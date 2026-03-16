import Foundation
import Capacitor
import Network

@objc public class WifiModule: NSObject, NetServiceDelegate {

    private let plugin: CAPPlugin

    private let local_network_permission_key = "Diagnostic_LocalNetworkPermission"
    private let local_network_default_timeout_seconds: TimeInterval = 2.0

    private enum LocalNetworkPermissionState: Int {
        case unknown = 0
        case granted = 1
        case denied = -1
        case indeterminate = -2
    }

    private var browser: nw_browser_t?
    private var net_service: NetService?
    private var local_network_calls: [CAPPluginCall] = []
    private var local_network_timer: Timer?
    private var is_publishing = false
    private var is_requesting = false

    init(plugin: CAPPlugin) {
        self.plugin = plugin
        super.init()
    }

    @objc public func getLocalNetworkAuthorizationStatus(_ call: CAPPluginCall) {
        DispatchQueue.global(qos: .background).async {
            let cached = UserDefaults.standard.integer(forKey: self.local_network_permission_key)
            let state = LocalNetworkPermissionState(rawValue: cached) ?? .unknown

            if state == .unknown {
                self.resolve_int(call, state.rawValue)
                self.log_debug("Local network permission status is NOT_REQUESTED")
                return
            }

            self.append_local_network_call(call)

            if self.is_requesting {
                self.log_debug("A request is already in progress, will return result when done")
                return
            }

            let timeout_seconds = self.resolve_local_network_timeout(from: call)

            if #available(iOS 14.0, *) {
                let parameters = nw_parameters_create_secure_tcp(NW_PARAMETERS_DISABLE_PROTOCOL, NW_PARAMETERS_DEFAULT_CONFIGURATION)
                nw_parameters_set_include_peer_to_peer(parameters, true)

                let descriptor = nw_browse_descriptor_create_bonjour_service("_bonjour._tcp", nil)
                self.browser = nw_browser_create(descriptor, parameters)

                if let browser = self.browser {
                    nw_browser_set_queue(browser, DispatchQueue.main)
                }

                self.net_service = NetService(domain: "local.", type: "_lnp._tcp.", name: "LocalNetworkPrivacy", port: 1100)

                self.is_requesting = true
                self.is_publishing = false

                self.log_debug("Starting local network permission status check (timeout \(String(format: "%.2f", timeout_seconds))s)")

                DispatchQueue.main.async {
                    guard !self.is_publishing else {
                        self.log_debug("Local network permission request already publishing, skipping start")
                        return
                    }

                    self.is_publishing = true
                    self.net_service?.delegate = self

                    if let browser = self.browser {
                        nw_browser_set_state_changed_handler(browser) { [weak self] new_state, error in
                            self?.handle_browser_state(new_state, error: error, context: "status check")
                        }
                        nw_browser_start(browser)
                    } else {
                        self.log_debug("Attempted to start browser but browser is null")
                    }

                    self.net_service?.publish()
                    self.net_service?.schedule(in: .main, forMode: .common)

                    if timeout_seconds > 0 {
                        self.local_network_timer = Timer.scheduledTimer(withTimeInterval: timeout_seconds, repeats: false) { [weak self] _ in
                            guard let self else { return }
                            self.log_debug("Local network permission status check timed out after \(String(format: "%.2f", timeout_seconds))s")
                            self.complete_local_network_flow(with: .indeterminate, should_cache: false)
                        }
                    }
                }
            } else {
                self.log_debug("iOS version < 14.0, so local network permission is not required")
                self.call_local_network_callbacks(.granted)
            }
        }
    }

    @objc public func requestLocalNetworkAuthorization(_ call: CAPPluginCall) {
        DispatchQueue.global(qos: .background).async {
            if self.is_requesting {
                call.reject("A request is already in progress")
                return
            }

            self.is_requesting = true
            self.append_local_network_call(call)

            if #available(iOS 14.0, *) {
                let parameters = nw_parameters_create_secure_tcp(NW_PARAMETERS_DISABLE_PROTOCOL, NW_PARAMETERS_DEFAULT_CONFIGURATION)
                nw_parameters_set_include_peer_to_peer(parameters, true)

                let descriptor = nw_browse_descriptor_create_bonjour_service("_bonjour._tcp", nil)
                self.browser = nw_browser_create(descriptor, parameters)

                if let browser = self.browser {
                    nw_browser_set_queue(browser, DispatchQueue.main)
                    nw_browser_set_state_changed_handler(browser) { [weak self] new_state, error in
                        self?.handle_browser_state(new_state, error: error, context: "authorization request")
                    }
                }

                self.net_service = NetService(domain: "local.", type: "_lnp._tcp.", name: "LocalNetworkPrivacy", port: 1100)
                self.net_service?.delegate = self

                DispatchQueue.main.async {
                    if let browser = self.browser {
                        nw_browser_start(browser)
                    }
                    self.net_service?.publish()
                    self.net_service?.schedule(in: .main, forMode: .common)
                }
            } else {
                self.call_local_network_callbacks(.granted)
            }
        }
    }


    @objc public func isWifiAvailable(_ call: CAPPluginCall) {
        DispatchQueue.global(qos: .background).async {
            self.resolve_bool(call, self.connected_to_wifi())
        }
    }

    @objc public func isWifiEnabled(_ call: CAPPluginCall) {
        DispatchQueue.global(qos: .background).async {
            self.resolve_bool(call, self.is_wifi_enabled())
        }
    }


    private func is_wifi_enabled() -> Bool {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        var counted_names: [String: Int] = [:]

        guard getifaddrs(&interfaces) == 0, let first = interfaces else {
            return false
        }

        defer { freeifaddrs(interfaces) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let current = cursor {
            let flags = Int32(current.pointee.ifa_flags)
            if (flags & IFF_UP) == IFF_UP, let name_c = current.pointee.ifa_name {
                let name = String(cString: name_c)
                counted_names[name, default: 0] += 1
            }
            cursor = current.pointee.ifa_next
        }

        return (counted_names["awdl0"] ?? 0) > 1
    }

    private func connected_to_wifi() -> Bool {
        var addresses: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&addresses) == 0, let first = addresses else {
            return false
        }

        defer { freeifaddrs(addresses) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let current = cursor {
            let interface = current.pointee

            if let addr = interface.ifa_addr,
               addr.pointee.sa_family == UInt8(AF_INET),
               (interface.ifa_flags & UInt32(IFF_LOOPBACK)) == 0,
               let name_c = interface.ifa_name {

                let name = String(cString: name_c)
                if name == "en0" {
                    self.log_debug("Wifi ON")
                    return true
                }
            }

            cursor = interface.ifa_next
        }

        return false
    }

    private func reset_local_network() {
        log_debug("resetting")

        local_network_timer?.invalidate()
        local_network_timer = nil

        is_publishing = false
        is_requesting = false

        if #available(iOS 13.0, *) {
            browser.map { nw_browser_cancel($0) }
        }
        browser = nil

        net_service?.stop()
        net_service = nil
    }

    private func call_local_network_callbacks(_ result: LocalNetworkPermissionState) {
        let calls = synchronized_take_local_network_calls()
        for call in calls {
            resolve_int(call, result.rawValue)
        }
    }

    private func complete_local_network_flow(with state: LocalNetworkPermissionState, should_cache: Bool) {
        let completion = {
            self.reset_local_network()

            if should_cache && (state == .granted || state == .denied) {
                UserDefaults.standard.set(state.rawValue, forKey: self.local_network_permission_key)
                UserDefaults.standard.synchronize()
            }

            self.call_local_network_callbacks(state)
        }

        if Thread.isMainThread {
            completion()
        } else {
            DispatchQueue.main.async(execute: completion)
        }
    }

    private func resolve_local_network_timeout(from call: CAPPluginCall) -> TimeInterval {
        guard
            let options = call.options as? [String: Any],
            let timeout_ms = options["timeoutMs"] as? NSNumber
        else {
            return local_network_default_timeout_seconds
        }

        let milliseconds = max(0, timeout_ms.doubleValue)
        return milliseconds / 1000.0
    }

    @available(iOS 13.0, *)
    private func is_permission_denied_error(_ error: nw_error_t?) -> Bool {
        guard let error else { return false }

        let domain = nw_error_get_error_domain(error)
        let code = Int32(nw_error_get_error_code(error))

        if domain == nw_error_domain_posix && code == EPERM {
            return true
        }

        if domain == nw_error_domain_dns && code == kDNSServiceErr_PolicyDenied {
            return true
        }

        return false
    }

    @available(iOS 13.0, *)
    private func handle_browser_state(_ new_state: nw_browser_state_t, error: nw_error_t?, context: String) {
        if new_state == nw_browser_state_waiting || new_state == nw_browser_state_failed {
            if is_permission_denied_error(error) {
                let domain = error.map { Int(nw_error_get_error_domain($0).rawValue) } ?? -1
                let code = error.map { Int(nw_error_get_error_code($0)) } ?? -1
                log_debug("Local network permission denied during \(context) (domain=\(domain), code=\(code))")
                complete_local_network_flow(with: .denied, should_cache: true)
                return
            }

            if let error {
                let domain = Int(nw_error_get_error_domain(error).rawValue)
                let code = Int(nw_error_get_error_code(error))
                log_debug("Local network browser \(context) state \(new_state.rawValue) error domain=\(domain) code=\(code)")
            } else {
                log_debug("Local network browser \(context) entered state \(new_state.rawValue) without error")
            }

            if new_state == nw_browser_state_failed {
                complete_local_network_flow(with: .indeterminate, should_cache: false)
            }
        }
    }

    public func netServiceDidPublish(_ sender: NetService) {
        log_debug("netServiceDidPublish: Local network permission has been granted")
        complete_local_network_flow(with: .granted, should_cache: true)
    }

    public func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        let error_domain = errorDict[NetService.errorDomain]
        let error_code = errorDict[NetService.errorCode]
        log_debug("netService didNotPublish (domain=\(String(describing: error_domain)), code=\(String(describing: error_code)))")
        complete_local_network_flow(with: .indeterminate, should_cache: false)
    }


    private func append_local_network_call(_ call: CAPPluginCall) {
        objc_sync_enter(self)
        local_network_calls.append(call)
        objc_sync_exit(self)
    }

    private func synchronized_take_local_network_calls() -> [CAPPluginCall] {
        objc_sync_enter(self)
        let calls = local_network_calls
        local_network_calls.removeAll()
        objc_sync_exit(self)
        return calls
    }

    private func resolve_bool(_ call: CAPPluginCall, _ value: Bool) {
        call.resolve(["value": value])
    }

    private func resolve_int(_ call: CAPPluginCall, _ value: Int) {
        call.resolve(["value": value])
    }

    private func log_debug(_ message: String) {
        CAPLog.print("[Diagnostic][Wifi] \(message)")
    }
}
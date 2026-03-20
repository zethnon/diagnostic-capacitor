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

    private var nw_browser_obj: NWBrowser?
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

            // Swift NWBrowser/NWParameters — replaces C NW_PARAMETERS_* macros
            let parameters = NWParameters(tls: nil, tcp: NWProtocolTCP.Options())
            parameters.includePeerToPeer = true

            let descriptor = NWBrowser.Descriptor.bonjour(type: "_bonjour._tcp", domain: nil)
            self.nw_browser_obj = NWBrowser(for: descriptor, using: parameters)

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

                if let browser = self.nw_browser_obj {
                    browser.stateUpdateHandler = { [weak self] state in
                        self?.handle_browser_state_swift(state, context: "status check")
                    }
                    browser.start(queue: DispatchQueue.main)
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

            let parameters = NWParameters(tls: nil, tcp: NWProtocolTCP.Options())
            parameters.includePeerToPeer = true

            let descriptor = NWBrowser.Descriptor.bonjour(type: "_bonjour._tcp", domain: nil)
            self.nw_browser_obj = NWBrowser(for: descriptor, using: parameters)

            self.nw_browser_obj?.stateUpdateHandler = { [weak self] state in
                self?.handle_browser_state_swift(state, context: "authorization request")
            }

            self.net_service = NetService(domain: "local.", type: "_lnp._tcp.", name: "LocalNetworkPrivacy", port: 1100)
            self.net_service?.delegate = self

            DispatchQueue.main.async {
                self.nw_browser_obj?.start(queue: DispatchQueue.main)
                self.net_service?.publish()
                self.net_service?.schedule(in: .main, forMode: .common)
            }
        }
    }

    @objc public func isWifiAvailable(_ call: CAPPluginCall) {
        DispatchQueue.global(qos: .background).async {
            call.resolve(["available": self.connected_to_wifi()])
        }
    }

    @objc public func isWifiEnabled(_ call: CAPPluginCall) {
        DispatchQueue.global(qos: .background).async {
            call.resolve(["enabled": self.is_wifi_enabled()])
        }
    }

    private func is_wifi_enabled() -> Bool {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        var counted_names: [String: Int] = [:]

        guard getifaddrs(&interfaces) == 0, let first = interfaces else { return false }
        defer { freeifaddrs(interfaces) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let current = cursor {
            let flags = Int32(current.pointee.ifa_flags)
            if (flags & IFF_UP) == IFF_UP, let name_c = current.pointee.ifa_name {
                counted_names[String(cString: name_c), default: 0] += 1
            }
            cursor = current.pointee.ifa_next
        }
        return (counted_names["awdl0"] ?? 0) > 1
    }

    private func connected_to_wifi() -> Bool {
        var addresses: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&addresses) == 0, let first = addresses else { return false }
        defer { freeifaddrs(addresses) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let current = cursor {
            let interface = current.pointee
            if let addr = interface.ifa_addr,
               addr.pointee.sa_family == UInt8(AF_INET),
               (interface.ifa_flags & UInt32(IFF_LOOPBACK)) == 0,
               let name_c = interface.ifa_name,
               String(cString: name_c) == "en0" {
                log_debug("Wifi ON")
                return true
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
        nw_browser_obj?.cancel()
        nw_browser_obj = nil
        net_service?.stop()
        net_service = nil
    }

    private func handle_browser_state_swift(_ state: NWBrowser.State, context: String) {
        switch state {
        case .waiting(let error):
            log_debug("Browser \(context) waiting: \(error)")
            if is_permission_denied(error) {
                complete_local_network_flow(with: .denied, should_cache: true)
            }
        case .failed(let error):
            log_debug("Browser \(context) failed: \(error)")
            if is_permission_denied(error) {
                complete_local_network_flow(with: .denied, should_cache: true)
            } else {
                complete_local_network_flow(with: .indeterminate, should_cache: false)
            }
        default:
            break
        }
    }

    private func is_permission_denied(_ error: NWError) -> Bool {
        if case .posix(let code) = error, code == .EPERM { return true }
        if case .dns(let code) = error, code == -65570 { return true } // kDNSServiceErr_PolicyDenied
        return false
    }

    private func call_local_network_callbacks(_ result: LocalNetworkPermissionState) {
        for call in synchronized_take_local_network_calls() {
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
        Thread.isMainThread ? completion() : DispatchQueue.main.async(execute: completion)
    }

    private func resolve_local_network_timeout(from call: CAPPluginCall) -> TimeInterval {
        guard let options = call.options as? [String: Any],
              let timeout_ms = options["timeoutMs"] as? NSNumber else {
            return local_network_default_timeout_seconds
        }
        return max(0, timeout_ms.doubleValue) / 1000.0
    }

    private func append_local_network_call(_ call: CAPPluginCall) {
        objc_sync_enter(self); local_network_calls.append(call); objc_sync_exit(self)
    }

    private func synchronized_take_local_network_calls() -> [CAPPluginCall] {
        objc_sync_enter(self)
        let calls = local_network_calls
        local_network_calls.removeAll()
        objc_sync_exit(self)
        return calls
    }

    public func netServiceDidPublish(_ sender: NetService) {
        log_debug("Local network permission granted")
        complete_local_network_flow(with: .granted, should_cache: true)
    }

    public func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        log_debug("netService didNotPublish: \(errorDict)")
        complete_local_network_flow(with: .indeterminate, should_cache: false)
    }

    private func resolve_bool(_ call: CAPPluginCall, _ value: Bool) { call.resolve(["value": value]) }
    private func resolve_int(_ call: CAPPluginCall, _ value: Int) { call.resolve(["value": value]) }
    private func log_debug(_ message: String) { CAPLog.print("[Diagnostic][Wifi] \(message)") }
}
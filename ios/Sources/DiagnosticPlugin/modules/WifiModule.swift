import Foundation
import Capacitor
import Network

/*
 * WifiModule handles WiFi state detection and local network authorization on iOS.
 *
 * iOS doesn't have a programmatic WiFi on/off API (Apple locked that down),
 * so this module covers what's actually possible:
 * - Detecting if the device is connected via WiFi (en0 interface check)
 * - Detecting if the WiFi radio is enabled at all (awdl0 interface heuristic)
 * - Local network permission — an iOS 14+ concept with no direct Android equivalent
 *
 * The local network check is the tricky one. iOS doesn't expose a clean API to
 * read local network permission status — the only way to probe it is to actually
 * attempt a local network operation and observe whether it succeeds or gets blocked.
 * We use NWBrowser + NetService for this, which is the same approach used by
 * several open-source implementations and Apple's own sample code.
 */
@objc public class WifiModule: NSObject, NetServiceDelegate {

    private let plugin: CAPPlugin

    // UserDefaults key for caching the last known local network permission result.
    // We persist this because the probe is async and can't always be repeated quickly.
    private let local_network_permission_key = "Diagnostic_LocalNetworkPermission"
    private let local_network_default_timeout_seconds: TimeInterval = 2.0

    // Raw integer values stored/returned for local network permission state.
    // Matches Cordova's numeric return for getLocalNetworkAuthorizationStatus.
    private enum LocalNetworkPermissionState: Int {
        case unknown = 0
        case granted = 1
        case denied = -1
        case indeterminate = -2  // timed out or inconclusive — not the same as denied
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

    /*
     * Returns { value: Int } — the cached or probed local network permission state.
     *
     * States:
     *   0  = unknown / never checked
     *   1  = granted
     *  -1  = denied
     *  -2  = indeterminate (probe timed out)
     *
     * If the cached state is "unknown", we skip the probe and return 0 immediately —
     * this matches Cordova's behavior of not triggering a permission probe just for a status check.
     * If a state has been cached (from a previous requestLocalNetworkAuthorization call),
     * we still run a fresh probe to confirm it hasn't changed, using the timeout parameter.
     */
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

    /*
     * Actively requests local network authorization by attempting a local network operation.
     *
     * This triggers the iOS local network permission prompt if it hasn't been shown yet.
     * The result is determined by NWBrowser state and NetService publish callbacks:
     * - netServiceDidPublish → granted (we successfully published to the local network)
     * - NWBrowser .waiting with EPERM or kDNSServiceErr_PolicyDenied → denied
     * - Anything else / timeout → indeterminate
     *
     * Results are cached to UserDefaults so getLocalNetworkAuthorizationStatus can
     * return a cached value on subsequent calls without re-probing.
     */
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

    /*
     * Returns { available: boolean } — true if the device is currently connected to a WiFi network.
     * Checks for an active IPv4 address on the "en0" interface (the WiFi interface on iOS devices).
     * Does not check if WiFi radio is enabled — only if there's an active WiFi connection.
     */
    @objc public func isWifiAvailable(_ call: CAPPluginCall) {
        DispatchQueue.global(qos: .background).async {
            call.resolve(["available": self.connected_to_wifi()])
        }
    }

    /*
     * Returns { enabled: boolean } — true if the WiFi radio is on, regardless of connection status.
     *
     * Apple doesn't provide a direct API for this. We use a heuristic:
     * the "awdl0" interface (Apple Wireless Direct Link — used for AirDrop/AirPlay)
     * appears multiple times in the interface list when WiFi is enabled.
     * This is an indirect signal but it's the most reliable approach available without
     * private APIs or entitlements.
     */
    @objc public func isWifiEnabled(_ call: CAPPluginCall) {
        DispatchQueue.global(qos: .background).async {
            call.resolve(["enabled": self.is_wifi_enabled()])
        }
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

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
        // awdl0 appears more than once when WiFi is active
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

    /*
     * Handles NWBrowser state transitions.
     * .waiting with EPERM or kDNSServiceErr_PolicyDenied (-65570) means local network is denied.
     * .failed is treated similarly. Any other state is ignored here.
     */
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

    // -------------------------------------------------------------------------
    // NetServiceDelegate
    // -------------------------------------------------------------------------

    /*
     * NetService successfully published → local network access is granted.
     */
    public func netServiceDidPublish(_ sender: NetService) {
        log_debug("Local network permission granted")
        complete_local_network_flow(with: .granted, should_cache: true)
    }

    /*
     * NetService failed to publish — could be a port conflict or other error.
     * Treated as indeterminate rather than denied since it's not a permission failure.
     */
    public func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        log_debug("netService didNotPublish: \(errorDict)")
        complete_local_network_flow(with: .indeterminate, should_cache: false)
    }

    private func resolve_bool(_ call: CAPPluginCall, _ value: Bool) { call.resolve(["value": value]) }
    private func resolve_int(_ call: CAPPluginCall, _ value: Int) { call.resolve(["value": value]) }
    private func log_debug(_ message: String) { CAPLog.print("[Diagnostic][Wifi] \(message)") }
}
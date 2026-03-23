import Foundation
import Capacitor
import CoreMotion

/*
 * MotionModule is iOS-only — Android has no direct equivalent for motion activity
 * authorization (step counting, activity recognition). CMMotionActivityManager
 * is what drives this on iOS.
 *
 * Important quirk: requestMotionAuthorization() can only be called once after
 * app installation. Calling it a second time is a no-op — CMMotionActivityManager
 * won't re-prompt the user. We guard against this with a UserDefaults flag and
 * reject the second call explicitly, matching Cordova behavior.
 *
 * Requires NSMotionUsageDescription in Info.plist.
 */
@objc public class MotionModule: NSObject {

    private let plugin: CAPPlugin

    private lazy var motion_manager = CMMotionActivityManager()
    private lazy var motion_activity_queue = OperationQueue()
    private lazy var cm_pedometer = CMPedometer()

    private let authorization_granted = "granted"
    private let authorization_denied = "denied"
    private let authorization_not_determined = "not_determined"
    private let status_not_available = "not_available"
    private let status_not_requested = "not_requested"
    private let status_restricted = "restricted"
    private let status_unknown = "unknown"

    // Persisted flag to track whether the permission prompt has ever been triggered.
    // Once set, it never resets — even after the user changes permission in Settings.
    private let motion_permission_requested_key = "motion_permission_requested"

    init(plugin: CAPPlugin) {
        self.plugin = plugin
        super.init()
    }

    /*
     * Returns { value: boolean } — true if motion activity hardware is available on this device.
     * M-series co-processors are present on iPhone 5s+, all current devices should return true.
     */
    @objc public func isMotionAvailable(_ call: CAPPluginCall) {
        call.resolve(["value": is_motion_available()])
    }

    /*
     * Returns { value: boolean } — true if the outcome of a motion request can be determined.
     * Uses CMPedometer.isPedometerEventTrackingAvailable() as the signal.
     * This maps to Cordova's isMotionRequestOutcomeAvailable().
     */
    @objc public func isMotionRequestOutcomeAvailable(_ call: CAPPluginCall) {
        call.resolve(["value": is_motion_request_outcome_available()])
    }

    /*
     * Returns { value: string } — current motion authorization status without prompting.
     *
     * If motion isn't available on this hardware → "not_available"
     * If permission was never requested → "not_requested"
     * Otherwise, fires a CMPedometer query to determine the actual status:
     *   - No error → "granted"
     *   - CMErrorMotionActivityNotAuthorized → "denied"
     *   - CMErrorMotionActivityNotEntitled → "restricted"
     *   - CMErrorMotionActivityNotAvailable → "not_determined"
     *   - Anything else → "unknown"
     */
    @objc public func getMotionAuthorizationStatus(_ call: CAPPluginCall) {
        if !is_motion_available() {
            call.resolve(["value": status_not_available])
            return
        }

        if !has_motion_permission_been_requested() {
            call.resolve(["value": status_not_requested])
            return
        }

        request_motion_authorization_internal(call)
    }

    /*
     * Triggers the motion permission prompt. iOS only allows this once per installation.
     * Rejects if already called before — the user must go to Settings to change it.
     *
     * Returns { value: string } — same status values as getMotionAuthorizationStatus.
     */
    @objc public func requestMotionAuthorization(_ call: CAPPluginCall) {
        if has_motion_permission_been_requested() {
            call.reject("requestMotionAuthorization() has already been called and can only be called once after app installation")
            return
        }

        request_motion_authorization_internal(call)
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    /*
     * The actual probe: queries CMPedometer for zero-length data starting now.
     * This is a standard trick to trigger the permission check — the query itself
     * is meaningless but the error code (or absence of one) tells us the auth state.
     * Sets the "requested" flag before reading the result so subsequent calls
     * correctly report something other than "not_requested".
     */
    private func request_motion_authorization_internal(_ call: CAPPluginCall) {
        if !is_motion_available() {
            call.resolve(["value": status_not_available])
            return
        }

        let now = Date()

        cm_pedometer.queryPedometerData(from: now, to: now) { _, error in
            self.set_motion_permission_requested()

            var status = self.status_unknown

            if let ns_error = error as NSError? {
                switch ns_error.code {
                case Int(CMErrorMotionActivityNotAuthorized.rawValue):
                    status = self.authorization_denied
                case Int(CMErrorMotionActivityNotEntitled.rawValue):
                    status = self.status_restricted
                case Int(CMErrorMotionActivityNotAvailable.rawValue):
                    status = self.authorization_not_determined
                default:
                    status = self.status_unknown
                }
            } else {
                status = self.authorization_granted
            }

            call.resolve(["value": status])
        }
    }

    private func is_motion_available() -> Bool {
        return CMMotionActivityManager.isActivityAvailable()
    }

    private func is_motion_request_outcome_available() -> Bool {
        return CMPedometer.responds(to: #selector(CMPedometer.isPedometerEventTrackingAvailable)) &&
            CMPedometer.isPedometerEventTrackingAvailable()
    }

    private func has_motion_permission_been_requested() -> Bool {
        return UserDefaults.standard.object(forKey: motion_permission_requested_key) != nil
    }

    private func set_motion_permission_requested() {
        UserDefaults.standard.set(true, forKey: motion_permission_requested_key)
    }
}
import Foundation
import Capacitor
import CoreMotion

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

    private let motion_permission_requested_key = "motion_permission_requested"

    init(plugin: CAPPlugin) {
        self.plugin = plugin
        super.init()
    }

    @objc public func isMotionAvailable(_ call: CAPPluginCall) {
        call.resolve([
            "value": is_motion_available()
        ])
    }

    @objc public func isMotionRequestOutcomeAvailable(_ call: CAPPluginCall) {
        call.resolve([
            "value": is_motion_request_outcome_available()
        ])
    }

    @objc public func getMotionAuthorizationStatus(_ call: CAPPluginCall) {
        if !is_motion_available() {
            call.resolve([
                "value": status_not_available
            ])
            return
        }

        if !has_motion_permission_been_requested() {
            call.resolve([
                "value": status_not_requested
            ])
            return
        }

        request_motion_authorization_internal(call)
    }

    @objc public func requestMotionAuthorization(_ call: CAPPluginCall) {
        if has_motion_permission_been_requested() {
            call.reject("requestMotionAuthorization() has already been called and can only be called once after app installation")
            return
        }

        request_motion_authorization_internal(call)
    }

    private func request_motion_authorization_internal(_ call: CAPPluginCall) {
        if !is_motion_available() {
            call.resolve([
                "value": status_not_available
            ])
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

            call.resolve([
                "value": status
            ])
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
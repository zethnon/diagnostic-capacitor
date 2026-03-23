import Foundation
import Capacitor
import CoreLocation
import UIKit

final class LocationModule: NSObject, CLLocationManagerDelegate {

    private let location_manager = CLLocationManager()

    // Holds the pending call from requestLocationAuthorization() until the
    // delegate fires a status change. Set to nil once resolved.
    private var pending_location_auth_call: CAPPluginCall?
    private var current_location_authorization_status: String?

    // iOS 14+ only — tracks accuracy authorization separately from location permission
    @available(iOS 14.0, *)
    private var current_location_accuracy_authorization: String?

    override init() {
        super.init()
        location_manager.delegate = self
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /*
     * iOS 14+ uses instance property authorizationStatus.
     * Before 14, the class method is the only option.
     */
    private func get_authorization_status() -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return location_manager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }

    /*
     * Maps CLAuthorizationStatus to Cordova-compatible strings.
     * Note: on iOS there's no "not_determined" for foreground/background split —
     * "authorizedAlways" maps to "granted" to match Cordova's iOS behavior.
     */
    private func auth_status_string(_ auth_status: CLAuthorizationStatus) -> String {
        switch auth_status {
        case .denied, .restricted:
            return "denied"
        case .notDetermined:
            return "not_determined"
        case .authorizedAlways:
            return "granted"
        case .authorizedWhenInUse:
            return "authorized_when_in_use"
        @unknown default:
            return "not_determined"
        }
    }

    private func is_location_authorized_internal() -> Bool {
        let status = auth_status_string(get_authorization_status())
        return status == "granted" || status == "authorized_when_in_use"
    }

    private func open_app_settings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    /*
     * Called by the CLLocationManagerDelegate whenever auth status changes.
     * Resolves the pending call if one exists, but only if the status actually changed.
     * This mirrors Cordova's behavior of returning only on state change.
     */
    private func report_change_authorization_status(_ auth_status: CLAuthorizationStatus) {
        let status = auth_status_string(auth_status)

        let changed: Bool
        if let current = current_location_authorization_status {
            changed = (status != current)
        } else {
            changed = true
        }
        current_location_authorization_status = status

        if changed {
            if let call = pending_location_auth_call {
                pending_location_auth_call = nil
                call.resolve(["status": status])
            }
        }
    }

    // -------------------------------------------------------------------------
    // Plugin methods
    // -------------------------------------------------------------------------

    /*
     * Returns { status: string } — current authorization status without prompting.
     */
    func getLocationAuthorizationStatus(_ call: CAPPluginCall) {
        call.resolve(["status": auth_status_string(get_authorization_status())])
    }

    /*
     * Triggers the location permission prompt if status is "not_determined".
     * If already determined (any status), resolves immediately with current status —
     * this avoids the call hanging when the user doesn't interact with the dialog,
     * which is a known Cordova quirk we preserve here.
     *
     * Requires NSLocationWhenInUseUsageDescription in Info.plist.
     * "always" mode additionally requires NSLocationAlwaysAndWhenInUseUsageDescription.
     */
    func requestLocationAuthorization(_ call: CAPPluginCall) {
        let mode = call.getString("mode") ?? "when_in_use"
        let always = (mode == "always")

        pending_location_auth_call = call

        let current = auth_status_string(get_authorization_status())
        if current != "not_determined" {
            pending_location_auth_call = nil
            call.resolve(["status": current])
            return
        }

        if always {
            let has_key = Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysAndWhenInUseUsageDescription") != nil
            if !has_key {
                pending_location_auth_call = nil
                call.reject("Missing NSLocationAlwaysAndWhenInUseUsageDescription in Info.plist")
                return
            }
            location_manager.requestAlwaysAuthorization()
        } else {
            let has_key = Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil
            if !has_key {
                pending_location_auth_call = nil
                call.reject("Missing NSLocationWhenInUseUsageDescription in Info.plist")
                return
            }
            location_manager.requestWhenInUseAuthorization()
        }
    }

    /*
     * Returns { enabled: boolean } — whether location services are enabled at the system level.
     * This is the iOS equivalent of Android's "location mode on/off" check.
     * Does not check app-level permission.
     */
    func isLocationEnabled(_ call: CAPPluginCall) {
        call.resolve(["enabled": CLLocationManager.locationServicesEnabled()])
    }

    /*
     * Returns { available: boolean } — location services are on AND the app is authorized.
     */
    func isLocationAvailable(_ call: CAPPluginCall) {
        let value = CLLocationManager.locationServicesEnabled() && is_location_authorized_internal()
        call.resolve(["available": value])
    }

    /*
     * Returns { mode: string }.
     * iOS doesn't have distinct location modes like Android (GPS only, network only, etc.).
     * If services are enabled we return "high_accuracy" to match Cordova's iOS output.
     */
    func getLocationMode(_ call: CAPPluginCall) {
        if !CLLocationManager.locationServicesEnabled() {
            call.resolve(["mode": "location_off"])
        } else {
            call.resolve(["mode": "high_accuracy"])
        }
    }

    /*
     * iOS doesn't separate GPS and network providers — both map to CLLocationManager.
     * These three methods all check the same underlying locationServicesEnabled() flag
     * to maintain Cordova API parity across platforms.
     */
    func isGpsLocationEnabled(_ call: CAPPluginCall) {
        call.resolve(["enabled": CLLocationManager.locationServicesEnabled()])
    }

    func isNetworkLocationEnabled(_ call: CAPPluginCall) {
        call.resolve(["enabled": CLLocationManager.locationServicesEnabled()])
    }

    func isGpsLocationAvailable(_ call: CAPPluginCall) {
        let value = CLLocationManager.locationServicesEnabled() && is_location_authorized_internal()
        call.resolve(["available": value])
    }

    func isNetworkLocationAvailable(_ call: CAPPluginCall) {
        let value = CLLocationManager.locationServicesEnabled() && is_location_authorized_internal()
        call.resolve(["available": value])
    }

    /*
     * Opens the app's page in Settings. Both open/switch to location settings
     * go to the same place on iOS — no direct link to the global location toggle.
     */
    func openLocationSettings(_ call: CAPPluginCall) {
        open_app_settings()
        call.resolve()
    }

    func switchToLocationSettings(_ call: CAPPluginCall) {
        open_app_settings()
        call.resolve()
    }

    /*
     * Returns { available: boolean } — checks for hardware compass (heading availability).
     */
    func isCompassAvailable(_ call: CAPPluginCall) {
        call.resolve(["available": CLLocationManager.headingAvailable()])
    }

    /*
     * Returns { value: boolean } — true if app has either whenInUse or always authorization.
     */
    func isLocationAuthorized(_ call: CAPPluginCall) {
        call.resolve(["value": is_location_authorized_internal()])
    }

    /*
     * Returns { value: "full" | "reduced" }.
     * iOS 14+ introduced reduced accuracy ("approximate location"). Below iOS 14 always returns "full".
     */
    func getLocationAccuracyAuthorization(_ call: CAPPluginCall) {
        if #available(iOS 14.0, *) {
            let accuracy = (location_manager.accuracyAuthorization == .fullAccuracy) ? "full" : "reduced"
            call.resolve(["value": accuracy])
        } else {
            call.resolve(["value": "full"])
        }
    }

    /*
     * Requests a temporary upgrade to full accuracy using a purpose key from Info.plist.
     * Only available on iOS 14+. Rejects cleanly on older versions.
     * Requires NSLocationTemporaryUsageDescriptionDictionary in Info.plist with a matching key.
     *
     * @param purpose — string key matching an entry in NSLocationTemporaryUsageDescriptionDictionary
     */
    func requestTemporaryFullAccuracyAuthorization(_ call: CAPPluginCall) {
        if #available(iOS 14.0, *) {
            let has_dict = Bundle.main.object(forInfoDictionaryKey: "NSLocationTemporaryUsageDescriptionDictionary") != nil
            if !has_dict {
                call.reject("Missing NSLocationTemporaryUsageDescriptionDictionary in Info.plist")
                return
            }
            guard let purpose = call.getString("purpose") else {
                call.reject("Missing purpose")
                return
            }

            location_manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: purpose) { error in
                if let error = error {
                    call.reject("Error when requesting temporary full location accuracy authorization: \(error)")
                } else {
                    let accuracy = (self.location_manager.accuracyAuthorization == .fullAccuracy) ? "full" : "reduced"
                    call.resolve(["value": accuracy])
                }
            }
        } else {
            call.reject("requestTemporaryFullAccuracyAuthorization is not available on iOS < 14")
        }
    }

    // -------------------------------------------------------------------------
    // CLLocationManagerDelegate
    // -------------------------------------------------------------------------

    /*
     * iOS 14+ combined delegate — handles both authorization and accuracy changes.
     * Fires report_change_authorization_status to resolve any pending auth calls.
     */
    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        report_change_authorization_status(manager.authorizationStatus)

        let accuracy = (manager.accuracyAuthorization == .fullAccuracy) ? "full" : "reduced"
        let changed: Bool
        if let current = current_location_accuracy_authorization {
            changed = (accuracy != current)
        } else {
            changed = true
        }
        current_location_accuracy_authorization = accuracy
        _ = changed
    }

    /*
     * Pre-iOS 14 delegate for authorization status changes.
     */
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        report_change_authorization_status(status)
    }
}
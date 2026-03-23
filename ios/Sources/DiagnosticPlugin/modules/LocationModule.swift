import Foundation
import Capacitor
import CoreLocation
import UIKit

/*
 * LocationModule handles location permission checks, state queries, and
 * location state change events on iOS.
 *
 * Location state changes are emitted via notifyListeners("locationStateChange")
 * when CLLocationManagerDelegate fires a status change. This fires on:
 * - User toggles location services globally in Settings
 * - User changes this app's location permission
 *
 * The plugin reference is weak to avoid a retain cycle.
 */
final class LocationModule: NSObject, CLLocationManagerDelegate {

    private let location_manager = CLLocationManager()
    private weak var plugin: CAPPlugin?

    private var pending_location_auth_call: CAPPluginCall?
    private var current_location_authorization_status: String?

    @available(iOS 14.0, *)
    private var current_location_accuracy_authorization: String?

    // Tracks last emitted state to deduplicate locationStateChange events
    private var last_emitted_location_state: String?

    init(plugin: CAPPlugin) {
        self.plugin = plugin
        super.init()
        location_manager.delegate = self
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private func get_authorization_status() -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return location_manager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }

    /*
     * Maps CLAuthorizationStatus to Cordova-compatible strings.
     */
    private func auth_status_string(_ auth_status: CLAuthorizationStatus) -> String {
        switch auth_status {
        case .denied, .restricted: return "denied"
        case .notDetermined: return "not_determined"
        case .authorizedAlways: return "granted"
        case .authorizedWhenInUse: return "authorized_when_in_use"
        @unknown default: return "not_determined"
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
     * Maps current state to a string for the locationStateChange event.
     * On iOS there are no separate GPS/network modes, so we use:
     * "location_off" when services are disabled globally,
     * otherwise the auth status string.
     */
    private func location_state_for_event(_ auth_status: CLAuthorizationStatus) -> String {
        if !CLLocationManager.locationServicesEnabled() {
            return "location_off"
        }
        return auth_status_string(auth_status)
    }

    /*
     * Resolves any pending requestLocationAuthorization() call on status change,
     * and emits a locationStateChange event if the state actually changed.
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

        // Resolve any pending auth call
        if changed, let call = pending_location_auth_call {
            pending_location_auth_call = nil
            call.resolve(["status": status])
        }

        // Emit locationStateChange event (deduped)
        let event_state = location_state_for_event(auth_status)
        if last_emitted_location_state == nil || last_emitted_location_state != event_state {
            last_emitted_location_state = event_state
            plugin?.notifyListeners("locationStateChange", data: ["state": event_state])
        }
    }

    // -------------------------------------------------------------------------
    // Plugin methods
    // -------------------------------------------------------------------------

    func getLocationAuthorizationStatus(_ call: CAPPluginCall) {
        call.resolve(["status": auth_status_string(get_authorization_status())])
    }

    /*
     * Triggers the location permission prompt if status is "not_determined".
     * If already determined, resolves immediately with the current status.
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

    func isLocationEnabled(_ call: CAPPluginCall) {
        call.resolve(["enabled": CLLocationManager.locationServicesEnabled()])
    }

    func isLocationAvailable(_ call: CAPPluginCall) {
        let value = CLLocationManager.locationServicesEnabled() && is_location_authorized_internal()
        call.resolve(["available": value])
    }

    /*
     * iOS has no separate GPS/network modes.
     * Returns "high_accuracy" when enabled, "location_off" when disabled.
     */
    func getLocationMode(_ call: CAPPluginCall) {
        if !CLLocationManager.locationServicesEnabled() {
            call.resolve(["mode": "location_off"])
        } else {
            call.resolve(["mode": "high_accuracy"])
        }
    }

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

    func openLocationSettings(_ call: CAPPluginCall) {
        open_app_settings()
        call.resolve()
    }

    func switchToLocationSettings(_ call: CAPPluginCall) {
        open_app_settings()
        call.resolve()
    }

    func isCompassAvailable(_ call: CAPPluginCall) {
        call.resolve(["available": CLLocationManager.headingAvailable()])
    }

    func isLocationAuthorized(_ call: CAPPluginCall) {
        call.resolve(["value": is_location_authorized_internal()])
    }

    func getLocationAccuracyAuthorization(_ call: CAPPluginCall) {
        if #available(iOS 14.0, *) {
            let accuracy = (location_manager.accuracyAuthorization == .fullAccuracy) ? "full" : "reduced"
            call.resolve(["value": accuracy])
        } else {
            call.resolve(["value": "full"])
        }
    }

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

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        report_change_authorization_status(status)
    }
}
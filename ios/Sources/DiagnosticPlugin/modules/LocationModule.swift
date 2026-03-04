import Foundation
import Capacitor
import CoreLocation
import UIKit

final class LocationModule: NSObject, CLLocationManagerDelegate {

    private let location_manager = CLLocationManager()

    private var pending_location_auth_call: CAPPluginCall?
    private var current_location_authorization_status: String?
    @available(iOS 14.0, *)
    private var current_location_accuracy_authorization: String?

    override init() {
        super.init()
        location_manager.delegate = self
    }


    private func get_authorization_status() -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return location_manager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }

    private func auth_status_string(_ auth_status: CLAuthorizationStatus) -> String {
        switch auth_status {
        case .denied, .restricted:
            return "DENIED"
        case .notDetermined:
            return "NOT_DETERMINED"
        case .authorizedAlways:
            return "GRANTED"
        case .authorizedWhenInUse:
            return "authorized_when_in_use"
        @unknown default:
            return "NOT_DETERMINED"
        }
    }

    private func is_location_authorized_internal() -> Bool {
        let status = auth_status_string(get_authorization_status())
        return status == "GRANTED" || status == "authorized_when_in_use"
    }

    private func open_app_settings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

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


    func getLocationAuthorizationStatus(_ call: CAPPluginCall) {
        call.resolve(["status": auth_status_string(get_authorization_status())])
    }

    func requestLocationAuthorization(_ call: CAPPluginCall) {
        let mode = call.getString("mode") ?? "when_in_use"
        let always = (mode == "always")

        pending_location_auth_call = call
        
        // in cordova, requestlocationauthorization only returns a status when it changes, oteriwse it keeps callback
        // but in case the status is already set and the user doesnt change it the promise will hang, this is why right after we set
        //the call , if the stauts is not alredy  NOT_DETERMINED, we resolve with the current status
        let current = auth_status_string(get_authorization_status())
        if current != "NOT_DETERMINED" {
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
            // cordova returns full for ios < 14
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
import Foundation
import Capacitor

@objc(DiagnosticPlugin)
public class DiagnosticPlugin: CAPPlugin {

    private lazy var location = LocationModule()

    @objc func getLocationAuthorizationStatus(_ call: CAPPluginCall) { location.getLocationAuthorizationStatus(call) }
    @objc func requestLocationAuthorization(_ call: CAPPluginCall) { location.requestLocationAuthorization(call) }

    @objc func openLocationSettings(_ call: CAPPluginCall) { location.openLocationSettings(call) }
    @objc func switchToLocationSettings(_ call: CAPPluginCall) { location.switchToLocationSettings(call) }

    @objc func isLocationEnabled(_ call: CAPPluginCall) { location.isLocationEnabled(call) }
    @objc func isLocationAvailable(_ call: CAPPluginCall) { location.isLocationAvailable(call) }

    @objc func isGpsLocationEnabled(_ call: CAPPluginCall) { location.isGpsLocationEnabled(call) }
    @objc func isNetworkLocationEnabled(_ call: CAPPluginCall) { location.isNetworkLocationEnabled(call) }

    @objc func isGpsLocationAvailable(_ call: CAPPluginCall) { location.isGpsLocationAvailable(call) }
    @objc func isNetworkLocationAvailable(_ call: CAPPluginCall) { location.isNetworkLocationAvailable(call) }

    @objc func getLocationMode(_ call: CAPPluginCall) { location.getLocationMode(call) }
    @objc func isCompassAvailable(_ call: CAPPluginCall) { location.isCompassAvailable(call) }

    @objc func isLocationAuthorized(_ call: CAPPluginCall) { location.isLocationAuthorized(call) }
    @objc func getLocationAccuracyAuthorization(_ call: CAPPluginCall) { location.getLocationAccuracyAuthorization(call) }
    @objc func requestTemporaryFullAccuracyAuthorization(_ call: CAPPluginCall) { location.requestTemporaryFullAccuracyAuthorization(call) }
}
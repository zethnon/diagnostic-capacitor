import Capacitor

@objc(DiagnosticPlugin)
public class DiagnosticPlugin: CAPPlugin {

    private lazy var location_module = LocationModule(plugin: self)

    @objc func getLocationAuthorizationStatus(_ call: CAPPluginCall) {
        location_module.get_location_authorization_status(call)
    }

    @objc func requestLocationAuthorization(_ call: CAPPluginCall) {
        location_module.request_location_authorization(call)
    }

    @objc func openLocationSettings(_ call: CAPPluginCall) {
        location_module.open_location_settings(call)
    }

    @objc func switchToLocationSettings(_ call: CAPPluginCall) {
        location_module.switch_to_location_settings(call)
    }

    @objc func isLocationEnabled(_ call: CAPPluginCall) {
        location_module.is_location_enabled(call)
    }

    @objc func isLocationAvailable(_ call: CAPPluginCall) {
        location_module.is_location_available(call)
    }

    @objc func isGpsLocationEnabled(_ call: CAPPluginCall) {
        location_module.is_gps_location_enabled(call)
    }

    @objc func isNetworkLocationEnabled(_ call: CAPPluginCall) {
        location_module.is_network_location_enabled(call)
    }

    @objc func isGpsLocationAvailable(_ call: CAPPluginCall) {
        location_module.is_gps_location_available(call)
    }

    @objc func isNetworkLocationAvailable(_ call: CAPPluginCall) {
        location_module.is_network_location_available(call)
    }

    @objc func getLocationMode(_ call: CAPPluginCall) {
        location_module.get_location_mode(call)
    }

    @objc func isCompassAvailable(_ call: CAPPluginCall) {
        location_module.is_compass_available(call)
    }
}
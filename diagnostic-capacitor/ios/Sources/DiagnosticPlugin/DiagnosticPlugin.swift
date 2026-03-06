import Foundation
import Capacitor

@objc(DiagnosticPlugin)
public class DiagnosticPlugin: CAPPlugin {

    private lazy var location = LocationModule()
    private lazy var bluetooth = BluetoothModule(plugin: self)

    // -----------------------
    // Location
    // -----------------------

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

    // -----------------------
    // Bluetooth
    // -----------------------

    @objc func switchToBluetoothSettings(_ call: CAPPluginCall) { bluetooth.switchToBluetoothSettings(call) }

    @objc func isBluetoothAvailable(_ call: CAPPluginCall) { bluetooth.isBluetoothAvailable(call) }
    @objc func isBluetoothEnabled(_ call: CAPPluginCall) { bluetooth.isBluetoothEnabled(call) }

    @objc func hasBluetoothSupport(_ call: CAPPluginCall) { bluetooth.hasBluetoothSupport(call) }
    @objc func hasBluetoothLESupport(_ call: CAPPluginCall) { bluetooth.hasBluetoothLESupport(call) }
    @objc func hasBluetoothLEPeripheralSupport(_ call: CAPPluginCall) { bluetooth.hasBluetoothLEPeripheralSupport(call) }

    @objc func setBluetoothState(_ call: CAPPluginCall) { bluetooth.setBluetoothState(call) }

    @objc func getBluetoothState(_ call: CAPPluginCall) { bluetooth.getBluetoothState(call) }

    @objc func getBluetoothAuthorizationStatuses(_ call: CAPPluginCall) { bluetooth.getBluetoothAuthorizationStatuses(call) }

    @objc func requestBluetoothAuthorization(_ call: CAPPluginCall) { bluetooth.requestBluetoothAuthorization(call) }

    @objc func ensureBluetoothManager(_ call: CAPPluginCall) { bluetooth.ensureBluetoothManager(call) }

    @objc func getBluetoothAuthorizationStatus(_ call: CAPPluginCall) { bluetooth.getBluetoothAuthorizationStatus(call) }
}
import Foundation
import Capacitor
import CoreBluetooth
import UIKit

class BluetoothModule: NSObject, CBCentralManagerDelegate {

    private weak var plugin: CAPPlugin?

    private let STATUS_GRANTED = "granted"
    private let STATUS_DENIED = "denied"
    private let STATUS_NOT_DETERMINED = "not_determined"

    private let BLUETOOTH_STATE_UNKNOWN = "unknown"
    private let BLUETOOTH_STATE_POWERED_ON = "powered_on"
    private let BLUETOOTH_STATE_POWERED_OFF = "powered_off"

    private var bluetoothManager: CBCentralManager?
    private var lastBluetoothState: String?
    private var pendingBluetoothAuthorizationCall: CAPPluginCall?

    init(plugin: CAPPlugin) {
        self.plugin = plugin
        super.init()
    }

    func switchToBluetoothSettings(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                call.reject("Failed to open settings")
                return
            }

            UIApplication.shared.open(url, options: [:]) { _ in
                call.resolve()
            }
        }
    }

    func isBluetoothAvailable(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            call.resolve([
                "available": self.hasBluetoothSupportValue() && self.isBluetoothEnabledValue()
            ])
        }
    }

    func isBluetoothEnabled(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            call.resolve([
                "enabled": self.isBluetoothEnabledValue()
            ])
        }
    }

    func hasBluetoothSupport(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            call.resolve([
                "supported": self.hasBluetoothSupportValue()
            ])
        }
    }

    func hasBluetoothLESupport(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            call.resolve([
                "supported": self.hasBluetoothSupportValue()
            ])
        }
    }

    func hasBluetoothLEPeripheralSupport(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            call.resolve([
                "supported": self.hasBluetoothSupportValue()
            ])
        }
    }

    func setBluetoothState(_ call: CAPPluginCall) {
        call.reject("Cannot change Bluetooth state on iOS")
    }

    func getBluetoothState(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            call.resolve([
                "state": self.getBluetoothStateValue()
            ])
        }
    }

    func getBluetoothAuthorizationStatuses(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let status = self.getBluetoothAuthorizationStatusValue()

            call.resolve([
                "statuses": [
                    "BLUETOOTH_ADVERTISE": status,
                    "BLUETOOTH_CONNECT": status,
                    "BLUETOOTH_SCAN": status
                ]
            ])
        }
    }

    func requestBluetoothAuthorization(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let currentStatus = self.getBluetoothAuthorizationStatusValue()

            if currentStatus != self.STATUS_NOT_DETERMINED {
                call.resolve([
                    "status": currentStatus
                ])
                return
            }

            self.pendingBluetoothAuthorizationCall = call
            self.ensureBluetoothManagerValue()
        }
    }

    func ensureBluetoothManager(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.ensureBluetoothManagerValue()
            call.resolve()
        }
    }

    func getBluetoothAuthorizationStatus(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            call.resolve([
                "status": self.getBluetoothAuthorizationStatusValue()
            ])
        }
    }

    private func ensureBluetoothManagerValue() {
        if bluetoothManager == nil {
            bluetoothManager = CBCentralManager(
                delegate: self,
                queue: DispatchQueue.main,
                options: [CBCentralManagerOptionShowPowerAlertKey: NSNumber(value: false)]
            )
        }
    }

    private func isBluetoothEnabledValue() -> Bool {
        return getBluetoothStateValue() == BLUETOOTH_STATE_POWERED_ON
    }

    private func hasBluetoothSupportValue() -> Bool {
        let state = getBluetoothStateValue()
        return state != "unsupported"
    }

   private func getBluetoothStateValue() -> String {
        ensureBluetoothManagerValue()

        guard let manager = bluetoothManager else {
            return BLUETOOTH_STATE_UNKNOWN
        }

        switch manager.state {
            case .poweredOff:
                return BLUETOOTH_STATE_POWERED_OFF
            case .poweredOn:
                return BLUETOOTH_STATE_POWERED_ON
            case .resetting:    
                return "resetting"
            case .unauthorized: 
                return "unauthorized"
            case .unsupported:  
                return "unsupported"
            case .unknown:      
                return BLUETOOTH_STATE_UNKNOWN
            @unknown default:
                return BLUETOOTH_STATE_UNKNOWN
        }
    } 

    private func getBluetoothAuthorizationStatusValue() -> String {
        if #available(iOS 13.0, *) {
            let authorization: CBManagerAuthorization

            if #available(iOS 13.1, *) {
                authorization = CBCentralManager.authorization
            } else {
                ensureBluetoothManagerValue()
                authorization = bluetoothManager?.authorization ?? .notDetermined
            }

            switch authorization {
            case .allowedAlways:
                return STATUS_GRANTED
            case .denied, .restricted:
                return STATUS_DENIED
            case .notDetermined:
                return STATUS_NOT_DETERMINED
            @unknown default:
                return STATUS_NOT_DETERMINED
            }
        } else {
            return STATUS_GRANTED
        }
    }

    private func notifyBluetoothStateChange(_ state: String) {
        plugin?.notifyListeners("bluetoothStateChange", data: [
            "state": state
        ])
    }

    private func resolvePendingBluetoothAuthorizationCallIfNeeded() {
        guard let call = pendingBluetoothAuthorizationCall else {
            return
        }

        let status = getBluetoothAuthorizationStatusValue()
        if status != STATUS_NOT_DETERMINED {
            pendingBluetoothAuthorizationCall = nil
            call.resolve([
                "status": status
            ])
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = getBluetoothStateValue()

        if lastBluetoothState == nil || lastBluetoothState != state {
            lastBluetoothState = state
            notifyBluetoothStateChange(state)
        }

        resolvePendingBluetoothAuthorizationCallIfNeeded()
    }
}
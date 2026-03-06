import Foundation
import Capacitor
import CoreBluetooth
import UIKit

class BluetoothModule: NSObject, CBCentralManagerDelegate {

    private weak var plugin: CAPPlugin?

    private let STATUS_GRANTED = "granted"
    private let STATUS_DENIED = "denied"
    private let STATUS_NOT_DETERMINED = "not_determined"

    private var bluetoothManager: CBCentralManager?
    private var lastBluetoothState: String?

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
            let state = self.getBluetoothStateValue()
            call.resolve(["available": state == "powered_on"])
        }
    }

    func isBluetoothEnabled(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let state = self.getBluetoothStateValue()
            call.resolve(["enabled": state == "powered_on"])
        }
    }

    func hasBluetoothSupport(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let state = self.getBluetoothStateValue()
            call.resolve(["supported": state != "unsupported"])
        }
    }

    func hasBluetoothLESupport(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let state = self.getBluetoothStateValue()
            call.resolve(["supported": state != "unsupported"])
        }
    }

    func hasBluetoothLEPeripheralSupport(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let state = self.getBluetoothStateValue()
            call.resolve(["supported": state != "unsupported"])
        }
    }

    func setBluetoothState(_ call: CAPPluginCall) {
        call.reject("Cannot change Bluetooth state on iOS")
    }

    func getBluetoothState(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            call.resolve(["state": self.getBluetoothStateValue()])
        }
    }

    func getBluetoothAuthorizationStatuses(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let auth = self.getBluetoothAuthorizationStatusValue()
            call.resolve([
                "statuses": [
                    "authorization": auth
                ]
            ])
        }
    }

    func requestBluetoothAuthorization(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let auth = self.getBluetoothAuthorizationStatusValue()

            if auth == self.STATUS_GRANTED {
                call.reject("Bluetooth authorization is already granted")
                return
            }

            if auth == self.STATUS_DENIED {
                call.reject("Bluetooth authorization has been denied")
                return
            }

            self.ensureBluetoothManagerValue()

            call.resolve([
                "status": self.STATUS_NOT_DETERMINED
            ])
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

            if let manager = bluetoothManager {
                centralManagerDidUpdateState(manager)
            }
        }
    }

    private func getBluetoothStateValue() -> String {
        ensureBluetoothManagerValue()

        guard let manager = bluetoothManager else {
            return "unknown"
        }

        switch manager.state {
        case .resetting:
            return "resetting"
        case .unsupported:
            return "unsupported"
        case .unauthorized:
            return "unauthorized"
        case .poweredOff:
            return "powered_off"
        case .poweredOn:
            return "powered_on"
        case .unknown:
            return "unknown"
        @unknown default:
            return "unknown"
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


    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = getBluetoothStateValue()

        if lastBluetoothState == nil || lastBluetoothState != state {
            lastBluetoothState = state
            notifyBluetoothStateChange(state)
        }
    }
}
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

    // CBCentralManager is lazily initialized — instantiating it triggers the
    // Bluetooth permission prompt on iOS 13+. We only create it when needed.
    private var bluetoothManager: CBCentralManager?
    private var lastBluetoothState: String?

    // Holds a pending requestBluetoothAuthorization() call until the
    // CBCentralManagerDelegate fires and we can confirm the status.
    private var pendingBluetoothAuthorizationCall: CAPPluginCall?

    init(plugin: CAPPlugin) {
        self.plugin = plugin
        super.init()
    }

    /*
     * Opens app Settings. No direct Bluetooth settings URL on iOS —
     * Settings is the closest we can get.
     */
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

    /*
     * Returns { available: boolean } — device has Bluetooth AND it's powered on.
     */
    func isBluetoothAvailable(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            call.resolve(["available": self.hasBluetoothSupportValue() && self.isBluetoothEnabledValue()])
        }
    }

    /*
     * Returns { enabled: boolean } — true if BT state is powered_on.
     */
    func isBluetoothEnabled(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            call.resolve(["enabled": self.isBluetoothEnabledValue()])
        }
    }

    /*
     * Returns { supported: boolean }.
     * On iOS, "unsupported" state from CBCentralManager means no BT hardware.
     */
    func hasBluetoothSupport(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            call.resolve(["supported": self.hasBluetoothSupportValue()])
        }
    }

    /*
     * Returns { supported: boolean }.
     * On iOS, BLE and classic BT both go through CoreBluetooth —
     * the support check is the same as hasBluetoothSupport.
     */
    func hasBluetoothLESupport(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            call.resolve(["supported": self.hasBluetoothSupportValue()])
        }
    }

    func hasBluetoothLEPeripheralSupport(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            call.resolve(["supported": self.hasBluetoothSupportValue()])
        }
    }

    /*
     * iOS doesn't allow apps to programmatically enable/disable Bluetooth.
     * Always rejects — matches Cordova iOS behavior.
     */
    func setBluetoothState(_ call: CAPPluginCall) {
        call.reject("Cannot change Bluetooth state on iOS")
    }

    /*
     * Returns { state: string } — one of: "powered_on", "powered_off",
     * "resetting", "unauthorized", "unsupported", "unknown".
     * Matches Cordova state strings.
     */
    func getBluetoothState(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            call.resolve(["state": self.getBluetoothStateValue()])
        }
    }

    /*
     * Returns { statuses: { BLUETOOTH_ADVERTISE, BLUETOOTH_CONNECT, BLUETOOTH_SCAN } }.
     * On iOS there's a single Bluetooth authorization — not three separate permissions
     * like Android 12+. All three keys return the same status for Cordova parity.
     */
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

    /*
     * Triggers the Bluetooth permission prompt on iOS 13+ by initializing CBCentralManager.
     * If status is already determined (not "not_determined"), resolves immediately.
     * The pending call is stored and resolved from centralManagerDidUpdateState() once
     * the manager fires its first state update after authorization.
     */
    func requestBluetoothAuthorization(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let currentStatus = self.getBluetoothAuthorizationStatusValue()

            if currentStatus != self.STATUS_NOT_DETERMINED {
                call.resolve(["status": currentStatus])
                return
            }

            self.pendingBluetoothAuthorizationCall = call
            self.ensureBluetoothManagerValue()
        }
    }

    /*
     * Initializes CBCentralManager if not already done.
     * On iOS 13+, instantiating CBCentralManager triggers the Bluetooth usage prompt.
     * This is called by ensureBluetoothManager() from JS and internally before state reads.
     */
    func ensureBluetoothManager(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.ensureBluetoothManagerValue()
            call.resolve()
        }
    }

    /*
     * Returns { status: string } — single combined Bluetooth authorization status.
     */
    func getBluetoothAuthorizationStatus(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            call.resolve(["status": self.getBluetoothAuthorizationStatusValue()])
        }
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    private func ensureBluetoothManagerValue() {
        if bluetoothManager == nil {
            bluetoothManager = CBCentralManager(
                delegate: self,
                queue: DispatchQueue.main,
                // Don't show the system power alert — we're just checking state
                options: [CBCentralManagerOptionShowPowerAlertKey: NSNumber(value: false)]
            )
        }
    }

    private func isBluetoothEnabledValue() -> Bool {
        return getBluetoothStateValue() == BLUETOOTH_STATE_POWERED_ON
    }

    private func hasBluetoothSupportValue() -> Bool {
        return getBluetoothStateValue() != "unsupported"
    }

    private func getBluetoothStateValue() -> String {
        ensureBluetoothManagerValue()

        guard let manager = bluetoothManager else {
            return BLUETOOTH_STATE_UNKNOWN
        }

        switch manager.state {
        case .poweredOff: return BLUETOOTH_STATE_POWERED_OFF
        case .poweredOn: return BLUETOOTH_STATE_POWERED_ON
        case .resetting: return "resetting"
        case .unauthorized: return "unauthorized"
        case .unsupported: return "unsupported"
        case .unknown: return BLUETOOTH_STATE_UNKNOWN
        @unknown default: return BLUETOOTH_STATE_UNKNOWN
        }
    }

    /*
     * Reads Bluetooth authorization from CBManagerAuthorization.
     * iOS 13.1+ uses class-level CBCentralManager.authorization.
     * iOS 13.0 uses instance-level bluetoothManager?.authorization.
     * Pre-iOS 13: no authorization required — always returns granted.
     */
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
            case .allowedAlways: return STATUS_GRANTED
            case .denied, .restricted: return STATUS_DENIED
            case .notDetermined: return STATUS_NOT_DETERMINED
            @unknown default: return STATUS_NOT_DETERMINED
            }
        } else {
            return STATUS_GRANTED
        }
    }

    private func notifyBluetoothStateChange(_ state: String) {
        plugin?.notifyListeners("bluetoothStateChange", data: ["state": state])
    }

    /*
     * Resolves any pending requestBluetoothAuthorization() call once the
     * authorization status is no longer "not_determined".
     */
    private func resolvePendingBluetoothAuthorizationCallIfNeeded() {
        guard let call = pendingBluetoothAuthorizationCall else { return }

        let status = getBluetoothAuthorizationStatusValue()
        if status != STATUS_NOT_DETERMINED {
            pendingBluetoothAuthorizationCall = nil
            call.resolve(["status": status])
        }
    }

    // -------------------------------------------------------------------------
    // CBCentralManagerDelegate
    // -------------------------------------------------------------------------

    /*
     * Fires whenever CBCentralManager state changes (power, authorization).
     * Emits bluetoothStateChange event (deduped) and resolves any pending auth call.
     */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = getBluetoothStateValue()

        if lastBluetoothState == nil || lastBluetoothState != state {
            lastBluetoothState = state
            notifyBluetoothStateChange(state)
        }

        resolvePendingBluetoothAuthorizationCallIfNeeded()
    }
}
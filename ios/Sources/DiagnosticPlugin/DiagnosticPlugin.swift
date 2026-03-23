import Foundation
import Capacitor

/*
 * DiagnosticPlugin — thin Capacitor bridge.
 *
 * This class does nothing but route @objc calls to the appropriate module.
 * All logic lives in the module files. Keep it that way.
 *
 * Note:
 * Modules are loaded lazily, wihch means they are instantiated on first access, not at plugin load.
 * This avoids triggering permission prompts or hardware initialization at startup.
 * The exception is BluetoothModule, which requires a plugin reference for event emission.
 *
 * SPM target split:
 * Plugin.m lives in DiagnosticPluginObjC (separate ObjC target) -  This was necessary because of building issues
 * All Swift files live in DiagnosticPlugin (Swift target).
 * This split is required because SPM doesn't support mixed ObjC/Swift in a single target.
 * Package.swift links both targets together.
 */
@objc(DiagnosticPlugin)
public class DiagnosticPlugin: CAPPlugin {
    

    private lazy var location = LocationModule(plugin: self)
    private lazy var bluetooth = BluetoothModule(plugin: self)
    private lazy var camera = CameraModule()
    private lazy var notifications = NotificationsModule(plugin: self)
    private lazy var wifi = WifiModule(plugin: self)
    private lazy var microphone = MicrophoneModule(plugin: self)
    private lazy var motion = MotionModule(plugin: self)
    private lazy var reminders = RemindersModule(plugin: self)
    private lazy var calendar = CalendarModule()
    private lazy var contacts = ContactsModule()
    private lazy var system = SystemModule(plugin: self)

    // -------------------------------------------------------------------------
    // General
    // -------------------------------------------------------------------------
    @objc func enableDebug(_ call: CAPPluginCall) {call.resolve()}

    // -------------------------------------------------------------------------
    // Location
    // -------------------------------------------------------------------------

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

    // -------------------------------------------------------------------------
    // Bluetooth
    // -------------------------------------------------------------------------

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

    // -------------------------------------------------------------------------
    // Camera
    // -------------------------------------------------------------------------

    @objc func isCameraPresent(_ call: CAPPluginCall) { camera.isCameraPresent(call) }
    @objc func requestCameraAuthorization(_ call: CAPPluginCall) { camera.requestCameraAuthorization(call) }
    @objc func getCameraAuthorizationStatus(_ call: CAPPluginCall) { camera.getCameraAuthorizationStatus(call) }
    @objc func getCameraAuthorizationStatuses(_ call: CAPPluginCall) { camera.getCameraAuthorizationStatuses(call) }

    // -------------------------------------------------------------------------
    // Notifications
    // -------------------------------------------------------------------------

    @objc func isRemoteNotificationsEnabled(_ call: CAPPluginCall) { notifications.isRemoteNotificationsEnabled(call) }
    @objc func getRemoteNotificationTypes(_ call: CAPPluginCall) { notifications.getRemoteNotificationTypes(call) }
    @objc func isRegisteredForRemoteNotifications(_ call: CAPPluginCall) { notifications.isRegisteredForRemoteNotifications(call) }
    @objc func getRemoteNotificationsAuthorizationStatus(_ call: CAPPluginCall) { notifications.getRemoteNotificationsAuthorizationStatus(call) }
    @objc func requestRemoteNotificationsAuthorization(_ call: CAPPluginCall) { notifications.requestRemoteNotificationsAuthorization(call) }
    @objc func switchToNotificationSettings(_ call: CAPPluginCall) { notifications.switchToNotificationSettings(call) }

    // -------------------------------------------------------------------------
    // WiFi
    // -------------------------------------------------------------------------

    @objc func isWifiAvailable(_ call: CAPPluginCall) { wifi.isWifiAvailable(call) }
    @objc func isWifiEnabled(_ call: CAPPluginCall) { wifi.isWifiEnabled(call) }
    @objc func requestLocalNetworkAuthorization(_ call: CAPPluginCall) { wifi.requestLocalNetworkAuthorization(call) }
    @objc func getLocalNetworkAuthorizationStatus(_ call: CAPPluginCall) { wifi.getLocalNetworkAuthorizationStatus(call) }

    // -------------------------------------------------------------------------
    // Microphone
    // -------------------------------------------------------------------------

    @objc func isMicrophoneAuthorized(_ call: CAPPluginCall) { microphone.isMicrophoneAuthorized(call) }
    @objc func getMicrophoneAuthorizationStatus(_ call: CAPPluginCall) { microphone.getMicrophoneAuthorizationStatus(call) }
    @objc func requestMicrophoneAuthorization(_ call: CAPPluginCall) { microphone.requestMicrophoneAuthorization(call) }

    // -------------------------------------------------------------------------
    // Motion
    // -------------------------------------------------------------------------

    @objc func isMotionAvailable(_ call: CAPPluginCall) { motion.isMotionAvailable(call) }
    @objc func isMotionRequestOutcomeAvailable(_ call: CAPPluginCall) { motion.isMotionRequestOutcomeAvailable(call) }
    @objc func getMotionAuthorizationStatus(_ call: CAPPluginCall) { motion.getMotionAuthorizationStatus(call) }
    @objc func requestMotionAuthorization(_ call: CAPPluginCall) { motion.requestMotionAuthorization(call) }

    // -------------------------------------------------------------------------
    // Reminders
    // -------------------------------------------------------------------------

    @objc func getRemindersAuthorizationStatus(_ call: CAPPluginCall) { reminders.getRemindersAuthorizationStatus(call) }
    @objc func isRemindersAuthorized(_ call: CAPPluginCall) { reminders.isRemindersAuthorized(call) }
    @objc func requestRemindersAuthorization(_ call: CAPPluginCall) { reminders.requestRemindersAuthorization(call) }

    // -------------------------------------------------------------------------
    // Calendar
    // -------------------------------------------------------------------------

    @objc func getCalendarAuthorizationStatus(_ call: CAPPluginCall) { calendar.getCalendarAuthorizationStatus(call) }
    @objc func isCalendarAuthorized(_ call: CAPPluginCall) { calendar.isCalendarAuthorized(call) }
    @objc func requestCalendarAuthorization(_ call: CAPPluginCall) { calendar.requestCalendarAuthorization(call) }

    // -------------------------------------------------------------------------
    // Contacts
    // -------------------------------------------------------------------------

    @objc func getAddressBookAuthorizationStatus(_ call: CAPPluginCall) { contacts.getAddressBookAuthorizationStatus(call) }
    @objc func isAddressBookAuthorized(_ call: CAPPluginCall) { contacts.isAddressBookAuthorized(call) }
    @objc func requestAddressBookAuthorization(_ call: CAPPluginCall) { contacts.requestAddressBookAuthorization(call) }

    // -------------------------------------------------------------------------
    // System
    // -------------------------------------------------------------------------

    @objc func switchToSettings(_ call: CAPPluginCall) { system.switchToSettings(call) }
    @objc func isBackgroundRefreshAuthorized(_ call: CAPPluginCall) { system.isBackgroundRefreshAuthorized(call) }
    @objc func enableDebug(_ call: CAPPluginCall) { call.resolve() } // No-op on Capacitor
 
    // Android-only stubs — resolve cleanly if called on iOS
    @objc func isADBModeEnabled(_ call: CAPPluginCall) {call.resolve(["enabled": false])}
    @objc func isDataRoamingEnabled(_ call: CAPPluginCall) {call.resolve(["enabled": false])}
    // App restart is not possible on iOS via public API
    @objc func restart(_ call: CAPPluginCall) {call.reject("Restart is not supported on iOS")}
    // There are no mobile data settings and wireless settins screen on iOS, so i decided these open general settings instead ¯\_(ツ)_/¯
    @objc func switchToMobileDataSettings(_ call: CAPPluginCall) {system.switchToSettings(call)}
    @objc func switchToWirelessSettings(_ call: CAPPluginCall) {system.switchToSettings(call)}
}
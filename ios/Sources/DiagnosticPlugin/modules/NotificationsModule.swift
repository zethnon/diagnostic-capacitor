import Foundation
import Capacitor
import UserNotifications
import UIKit

@objc public class NotificationsModule: NSObject {

    private let plugin: CAPPlugin

    private let status_granted = "granted"
    private let status_denied = "denied"
    private let status_not_determined = "not_determined"
    private let status_provisional = "provisional"   // iOS 12+ — authorized quietly, no prompt
    private let status_ephemeral = "ephemeral"       // iOS 14+ — used for App Clips
    private let status_unknown = "unknown"

    private let remote_notifications_alert = "alert"
    private let remote_notifications_sound = "sound"
    private let remote_notifications_badge = "badge"

    init(plugin: CAPPlugin) {
        self.plugin = plugin
        super.init()
    }

    /*
     * Returns { enabled: boolean }.
     * True only if both conditions hold:
     * 1. System authorization is .authorized (not provisional/denied)
     * 2. The app is actually registered for remote notifications
     */
    @objc public func isRemoteNotificationsEnabled(_ call: CAPPluginCall) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let user_setting_enabled = settings.authorizationStatus == .authorized
            self.isRegisteredForRemoteNotificationsValue { registered in
                let enabled = registered && user_setting_enabled
                call.resolve(["enabled": enabled])
            }
        }
    }

    /*
     * Returns { types: { alert, sound, badge } } with "1" or "0" values.
     * Reads per-type settings from UNNotificationSettings.
     * This is more accurate than Android where all types mirror a single enabled flag.
     */
    @objc public func getRemoteNotificationTypes(_ call: CAPPluginCall) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let alerts_enabled = settings.alertSetting == .enabled
            let badges_enabled = settings.badgeSetting == .enabled
            let sounds_enabled = settings.soundSetting == .enabled

            call.resolve([
                "types": [
                    self.remote_notifications_alert: alerts_enabled ? "1" : "0",
                    self.remote_notifications_badge: badges_enabled ? "1" : "0",
                    self.remote_notifications_sound: sounds_enabled ? "1" : "0"
                ]
            ])
        }
    }

    /*
     * Returns { registered: boolean } — whether the app is registered with APNs.
     * Must be checked on the main thread.
     */
    @objc public func isRegisteredForRemoteNotifications(_ call: CAPPluginCall) {
        isRegisteredForRemoteNotificationsValue { registered in
            call.resolve(["registered": registered])
        }
    }

    /*
     * Returns { status: string } — the UNAuthorizationStatus mapped to Cordova strings.
     * Possible values: "granted", "denied", "not_determined", "provisional", "ephemeral".
     */
    @objc public func getRemoteNotificationsAuthorizationStatus(_ call: CAPPluginCall) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            call.resolve(["status": self.mapAuthorizationStatus(settings.authorizationStatus)])
        }
    }

    /*
     * Requests notification authorization and registers for remote notifications if granted.
     *
     * @param types — optional array of ["alert", "sound", "badge"]. Defaults to all three.
     * @param omitRegistration — bool, if true skips registerForRemoteNotifications() after grant.
     *
     * Will re-request if currently provisional or ephemeral (allowing upgrade to full authorization).
     * If already authorized, re-registers and resolves immediately.
     * If denied, rejects — user must go to Settings.
     */
    @objc public func requestRemoteNotificationsAuthorization(_ call: CAPPluginCall) {
        var requested_types = call.getArray("types", String.self)

        if requested_types == nil || requested_types?.isEmpty == true {
            requested_types = [remote_notifications_alert, remote_notifications_sound, remote_notifications_badge]
        }

        let omit_registration = call.getBool("omitRegistration") ?? false

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let auth_status = settings.authorizationStatus
            let should_ask =
                auth_status == .notDetermined ||
                (self.isProvisional(auth_status)) ||
                (self.isEphemeral(auth_status))

            if should_ask {
                let options = self.buildAuthorizationOptions(from: requested_types ?? [])

                UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
                    if let error = error {
                        call.reject("Error when requesting remote notifications authorization: \(error.localizedDescription)")
                        return
                    }

                    if granted {
                        if !omit_registration {
                            DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications()
                                call.resolve(["status": self.status_granted])
                            }
                        } else {
                            call.resolve(["status": self.status_granted])
                        }
                    } else {
                        call.reject("Remote notifications authorization was denied")
                    }
                }

                return
            }

            if auth_status == .authorized {
                if !omit_registration {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                        call.resolve(["status": self.status_granted])
                    }
                } else {
                    call.resolve(["status": self.status_granted])
                }
                return
            }

            if auth_status == .denied {
                call.reject("Remote notifications authorization is denied")
                return
            }

            call.resolve(["status": self.mapAuthorizationStatus(auth_status)])
        }
    }

    /*
     * Opens notification settings.
     * iOS 16+: UIApplication.openNotificationSettingsURLString goes directly to notification prefs.
     * Pre-iOS 16: falls back to generic openSettingsURLString.
     */
    @objc public func switchToNotificationSettings(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let application = UIApplication.shared

            if #available(iOS 16.0, *) {
                guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else {
                    call.reject("Failed to build notification settings URL")
                    return
                }

                application.open(url, options: [:]) { success in
                    if success { call.resolve() } else { call.reject("Failed to open notification settings") }
                }
            } else {
                guard let url = URL(string: UIApplication.openSettingsURLString) else {
                    call.reject("Failed to build settings URL")
                    return
                }

                application.open(url, options: [:]) { success in
                    if success { call.resolve() } else { call.reject("Failed to open notification settings") }
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    private func isRegisteredForRemoteNotificationsValue(_ completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            completion(UIApplication.shared.isRegisteredForRemoteNotifications)
        }
    }

    private func buildAuthorizationOptions(from types: [String]) -> UNAuthorizationOptions {
        var options: UNAuthorizationOptions = []

        for type in types {
            if type == remote_notifications_alert { options.insert(.alert) }
            else if type == remote_notifications_sound { options.insert(.sound) }
            else if type == remote_notifications_badge { options.insert(.badge) }
        }

        return options
    }

    private func mapAuthorizationStatus(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .denied: return status_denied
        case .notDetermined: return status_not_determined
        case .authorized: return status_granted
        case .provisional: return status_provisional
        case .ephemeral: return status_ephemeral
        @unknown default: return status_unknown
        }
    }

    private func isProvisional(_ status: UNAuthorizationStatus) -> Bool {
        if #available(iOS 12.0, *) { return status == .provisional }
        return false
    }

    private func isEphemeral(_ status: UNAuthorizationStatus) -> Bool {
        if #available(iOS 14.0, *) { return status == .ephemeral }
        return false
    }
}
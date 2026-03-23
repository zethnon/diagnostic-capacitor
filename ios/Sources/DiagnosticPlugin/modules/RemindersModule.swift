import Foundation
import Capacitor
import EventKit

/*
 * RemindersModule is iOS-only — Android has no equivalent reminders permission.
 *
 * Uses EKEventStore with entity type .reminder for all authorization checks.
 * iOS 17 introduced a new requestFullAccessToReminders() API alongside the old
 * requestAccess(to: .reminder) — we handle both code paths.
 *
 * Requires NSRemindersUsageDescription in Info.plist.
 */
@objc public class RemindersModule: NSObject {

    private let plugin: CAPPlugin
    private var event_store: EKEventStore?

    private let authorization_granted = "granted"
    private let authorization_denied = "denied"
    private let authorization_not_determined = "not_determined"

    init(plugin: CAPPlugin) {
        self.plugin = plugin
        super.init()
    }

    /*
     * Returns { value: string } — current reminders authorization status without prompting.
     * Maps EKAuthorizationStatus to Cordova-compatible strings.
     *
     * iOS 17+ adds .fullAccess and .writeOnly in addition to the legacy statuses.
     * .writeOnly maps to "denied" — write-only isn't enough for the Cordova surface.
     */
    @objc public func getRemindersAuthorizationStatus(_ call: CAPPluginCall) {
        let auth_status = EKEventStore.authorizationStatus(for: .reminder)
        call.resolve(["value": map_authorization_status(auth_status)])
    }

    /*
     * Returns { value: boolean } — true if reminders are authorized.
     *
     * iOS 17+: both .authorized and .fullAccess count as authorized.
     * Pre-iOS 17: only .authorized.
     */
    @objc public func isRemindersAuthorized(_ call: CAPPluginCall) {
        let auth_status = EKEventStore.authorizationStatus(for: .reminder)

        let authorized: Bool

        if #available(iOS 17.0, *) {
            authorized = auth_status == .authorized || auth_status == .fullAccess
        } else {
            authorized = auth_status == .authorized
        }

        call.resolve(["value": authorized])
    }

    /*
     * Triggers the reminders permission prompt.
     * Returns { value: boolean } — true if access was granted.
     *
     * iOS 17+: uses requestFullAccessToReminders() which maps to the new full-access grant.
     * Pre-iOS 17: uses the legacy requestAccess(to: .reminder).
     *
     * EKEventStore is created lazily here — initializing it too early can
     * trigger the prompt unexpectedly on some iOS versions.
     */
    @objc public func requestRemindersAuthorization(_ call: CAPPluginCall) {
        if event_store == nil {
            event_store = EKEventStore()
        }

        guard let event_store else {
            call.resolve(["value": false])
            return
        }

        if #available(iOS 17.0, *) {
            event_store.requestFullAccessToReminders { granted, _ in
                call.resolve(["value": granted])
            }
        } else {
            event_store.requestAccess(to: .reminder) { granted, _ in
                call.resolve(["value": granted])
            }
        }
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    /*
     * Maps EKAuthorizationStatus to Cordova-compatible strings.
     * .fullAccess (iOS 17+) → "granted"
     * .writeOnly (iOS 17+) → "denied" — partial access isn't enough
     * .authorized → "granted"
     * .denied / .restricted → "denied"
     * .notDetermined → "not_determined"
     */
    private func map_authorization_status(_ auth_status: EKAuthorizationStatus) -> String {
        switch auth_status {
        case .authorized: return authorization_granted
        case .fullAccess: return authorization_granted
        case .writeOnly: return authorization_denied
        case .denied: return authorization_denied
        case .restricted: return authorization_denied
        case .notDetermined: return authorization_not_determined
        @unknown default: return authorization_not_determined
        }
    }
}
import Foundation
import Capacitor
import EventKit

/*
 * CalendarModule is iOS-only — Android handles calendar access at the manifest
 * level and doesn't expose it through this plugin's diagnostic surface.
 *
 * Uses EKEventStore with entity type .event for all authorization checks.
 * iOS 17 split calendar access into .fullAccess and .writeOnly, alongside
 * the legacy .authorized. We handle all three code paths.
 *
 * Note: .writeOnly is treated as "granted" here — Cordova's iOS behavior
 * maps write-only access as sufficient for a positive authorization state.
 * This differs from RemindersModule where write-only is treated as denied.
 *
 * Requires NSCalendarsUsageDescription in Info.plist.
 */
@objc public class CalendarModule: NSObject {

    private let status_granted = "granted"
    private let status_denied = "denied"
    private let status_not_determined = "not_determined"

    private var event_store: EKEventStore?

    /*
     * Returns { value: string } — current calendar authorization status without prompting.
     * Runs on a background queue since EKEventStore.authorizationStatus can take a moment.
     */
    @objc public func getCalendarAuthorizationStatus(_ call: CAPPluginCall) {
        DispatchQueue.global(qos: .userInitiated).async {
            let auth_status = EKEventStore.authorizationStatus(for: .event)
            call.resolve(["value": self.map_calendar_status(auth_status)])
        }
    }

    /*
     * Returns { value: boolean } — true if calendar is authorized.
     *
     * iOS 17+: both .authorized and .fullAccess count.
     * Pre-iOS 17: only .authorized.
     */
    @objc public func isCalendarAuthorized(_ call: CAPPluginCall) {
        DispatchQueue.global(qos: .userInitiated).async {
            let auth_status = EKEventStore.authorizationStatus(for: .event)

            let authorized: Bool

            if #available(iOS 17.0, *) {
                authorized = (auth_status == .authorized || auth_status == .fullAccess)
            } else {
                authorized = (auth_status == .authorized)
            }

            call.resolve(["value": authorized])
        }
    }

    /*
     * Triggers the calendar permission prompt.
     * Returns { value: boolean } — true if access was granted.
     *
     * iOS 17+: uses requestFullAccessToEvents().
     * Pre-iOS 17: uses the legacy requestAccess(to: .event).
     *
     * EKEventStore is created lazily — creating it too early in the app lifecycle
     * can cause unexpected permission prompts on some iOS versions.
     */
    @objc public func requestCalendarAuthorization(_ call: CAPPluginCall) {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.event_store == nil {
                self.event_store = EKEventStore()
            }

            guard let event_store = self.event_store else {
                call.reject("Failed to create EKEventStore")
                return
            }

            if #available(iOS 17.0, *) {
                event_store.requestFullAccessToEvents { granted, error in
                    if let error = error {
                        call.reject(error.localizedDescription)
                        return
                    }
                    call.resolve(["value": granted])
                }
            } else {
                event_store.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        call.reject(error.localizedDescription)
                        return
                    }
                    call.resolve(["value": granted])
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    /*
     * Maps EKAuthorizationStatus to Cordova-compatible strings.
     *
     * iOS 17+ statuses:
     * .fullAccess → "granted"
     * .writeOnly  → "granted" (Cordova treats write-only as sufficient for calendar)
     *
     * Legacy + shared:
     * .authorized → "granted"
     * .denied / .restricted → "denied"
     * .notDetermined → "not_determined"
     */
    private func map_calendar_status(_ status: EKAuthorizationStatus) -> String {
        switch status {
        case .authorized: return status_granted
        case .denied, .restricted: return status_denied
        case .notDetermined: return status_not_determined
        case .fullAccess: return status_granted
        case .writeOnly: return status_granted
        @unknown default: return status_not_determined
        }
    }
}
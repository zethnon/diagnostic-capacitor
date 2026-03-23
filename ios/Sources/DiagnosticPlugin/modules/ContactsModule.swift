import Foundation
import Capacitor
import Contacts

/*
 * ContactsModule is iOS-only — Android surfaces contacts access through the
 * Cordova plugin's existing permission model, not through this diagnostic surface.
 *
 * Uses CNContactStore for all authorization checks and requests.
 * The contact_store instance is created at init time — unlike EKEventStore,
 * CNContactStore initialization doesn't trigger any prompts on its own.
 *
 * Requires NSContactsUsageDescription in Info.plist.
 */
@objc public class ContactsModule: NSObject {

    private let status_granted = "granted"
    private let status_denied = "denied"
    private let status_not_determined = "not_determined"

    private let contact_store = CNContactStore()

    /*
     * Returns { value: string } — current contacts authorization status without prompting.
     * Runs on a background queue since CNContactStore authorization checks can be slow.
     *
     * CNAuthorizationStatus.limited (iOS 18+) maps to "granted" —
     * limited access still allows the app to work with contacts, and Cordova
     * doesn't have a "limited" state for contacts.
     */
    @objc public func getAddressBookAuthorizationStatus(_ call: CAPPluginCall) {
        DispatchQueue.global(qos: .userInitiated).async {
            let auth_status = CNContactStore.authorizationStatus(for: .contacts)
            call.resolve(["value": self.map_contacts_status(auth_status)])
        }
    }

    /*
     * Returns { value: boolean } — true if contacts are fully authorized.
     * Note: .limited is not checked here — only .authorized counts as fully authorized.
     * This matches Cordova behavior where isAddressBookAuthorized returns a strict boolean.
     */
    @objc public func isAddressBookAuthorized(_ call: CAPPluginCall) {
        DispatchQueue.global(qos: .userInitiated).async {
            let auth_status = CNContactStore.authorizationStatus(for: .contacts)
            call.resolve(["value": auth_status == .authorized])
        }
    }

    /*
     * Triggers the contacts permission prompt.
     * Returns { value: boolean } — true if access was granted.
     * If already determined, CNContactStore will return the existing state without re-prompting.
     */
    @objc public func requestAddressBookAuthorization(_ call: CAPPluginCall) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.contact_store.requestAccess(for: .contacts) { granted, error in
                if let _ = error {
                    call.resolve(["value": false])
                    return
                }
                call.resolve(["value": granted])
            }
        }
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    /*
     * Maps CNAuthorizationStatus to Cordova-compatible strings.
     * .limited (iOS 18+) maps to "granted" for parity — Cordova has no "limited" contacts state.
     */
    private func map_contacts_status(_ status: CNAuthorizationStatus) -> String {
        switch status {
        case .authorized: return status_granted
        case .denied, .restricted: return status_denied
        case .notDetermined: return status_not_determined
        case .limited: return status_granted
        @unknown default: return status_not_determined
        }
    }
}
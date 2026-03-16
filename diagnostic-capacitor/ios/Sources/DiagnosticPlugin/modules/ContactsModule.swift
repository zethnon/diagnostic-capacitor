// ios/Sources/DiagnosticPlugin/modules/ContactsModule.swift

import Foundation
import Capacitor
import Contacts

@objc public class ContactsModule: NSObject {

    private let status_granted = "granted"
    private let status_denied = "denied"
    private let status_not_determined = "not_determined"

    private let contact_store = CNContactStore()

    @objc public func getAddressBookAuthorizationStatus(_ call: CAPPluginCall) {
        DispatchQueue.global(qos: .userInitiated).async {
            let auth_status = CNContactStore.authorizationStatus(for: .contacts)
            let status = self.map_contacts_status(auth_status)

            call.resolve([
                "value": status
            ])
        }
    }

    @objc public func isAddressBookAuthorized(_ call: CAPPluginCall) {
        DispatchQueue.global(qos: .userInitiated).async {
            let auth_status = CNContactStore.authorizationStatus(for: .contacts)

            call.resolve([
                "value": auth_status == .authorized
            ])
        }
    }

    @objc public func requestAddressBookAuthorization(_ call: CAPPluginCall) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.contact_store.requestAccess(for: .contacts) { granted, error in
                if let _ = error {
                    call.resolve([
                        "value": false
                    ])
                    return
                }

                call.resolve([
                    "value": granted
                ])
            }
        }
    }

    private func map_contacts_status(_ status: CNAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return status_granted
        case .denied, .restricted:
            return status_denied
        case .notDetermined:
            return status_not_determined
        case .limited:
            return status_granted
        @unknown default:
            return status_not_determined
        }
    }
}
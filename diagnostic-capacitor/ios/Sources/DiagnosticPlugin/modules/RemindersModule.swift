import Foundation
import Capacitor
import EventKit

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

    @objc public func getRemindersAuthorizationStatus(_ call: CAPPluginCall) {
        let auth_status = EKEventStore.authorizationStatus(for: .reminder)
        let status = map_authorization_status(auth_status)

        call.resolve([
            "value": status
        ])
    }

    @objc public func isRemindersAuthorized(_ call: CAPPluginCall) {
        let auth_status = EKEventStore.authorizationStatus(for: .reminder)

        call.resolve([
            "value": auth_status == .authorized || auth_status == .fullAccess
        ])
    }

    @objc public func requestRemindersAuthorization(_ call: CAPPluginCall) {
        if event_store == nil {
            event_store = EKEventStore()
        }

        guard let event_store else {
            call.resolve([
                "value": false
            ])
            return
        }

        if #available(iOS 17.0, *) {
            event_store.requestFullAccessToReminders { granted, _ in
                call.resolve([
                    "value": granted
                ])
            }
        } else {
            event_store.requestAccess(to: .reminder) { granted, _ in
                call.resolve([
                    "value": granted
                ])
            }
        }
    }

    private func map_authorization_status(_ auth_status: EKAuthorizationStatus) -> String {
        switch auth_status {
        case .authorized:
            return authorization_granted
        case .fullAccess:
            return authorization_granted
        case .writeOnly:
            return authorization_denied
        case .denied:
            return authorization_denied
        case .restricted:
            return authorization_denied
        case .notDetermined:
            return authorization_not_determined
        @unknown default:
            return authorization_not_determined
        }
    }
}
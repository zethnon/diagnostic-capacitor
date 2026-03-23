import Foundation
import Capacitor
import EventKit

@objc public class CalendarModule: NSObject {

    private let status_granted = "granted"
    private let status_denied = "denied"
    private let status_not_determined = "not_determined"

    private var event_store: EKEventStore?

    @objc public func getCalendarAuthorizationStatus(_ call: CAPPluginCall) {
        DispatchQueue.global(qos: .userInitiated).async {
            let auth_status = EKEventStore.authorizationStatus(for: .event)
            let status = self.map_calendar_status(auth_status)

            call.resolve([
                "value": status
            ])
        }
    }


    @objc public func isCalendarAuthorized(_ call: CAPPluginCall) {
        DispatchQueue.global(qos: .userInitiated).async {
            let auth_status = EKEventStore.authorizationStatus(for: .event)
            
            let authorized: Bool
            
            //iOS 17+ only needs an #available guard
            if #available(iOS 17.0, *) {
                authorized = (auth_status == .authorized || auth_status == .fullAccess)
            } else {
                authorized = (auth_status == .authorized)
            }
            
            call.resolve(["value": authorized])
        }
    }

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

                    call.resolve([
                        "value": granted
                    ])
                }
            } else {
                event_store.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        call.reject(error.localizedDescription)
                        return
                    }

                    call.resolve([
                        "value": granted
                    ])
                }
            }
        }
    }

    private func map_calendar_status(_ status: EKAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return status_granted
        case .denied, .restricted:
            return status_denied
        case .notDetermined:
            return status_not_determined
        case .fullAccess:
            return status_granted
        case .writeOnly:
            return status_granted
        @unknown default:
            return status_not_determined
        }
    }
}
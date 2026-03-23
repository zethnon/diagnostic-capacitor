import Foundation
import Capacitor
import UIKit

/*
 * SystemModule handles system-level diagnostics and settings navigation on iOS.
 *
 * switchToSettings — opens the app's own Settings page.
 * isBackgroundRefreshAuthorized — checks UIBackgroundRefreshStatus.
 *
 * Restart is not possible on iOS — the OS doesn't expose any public API for it.
 * ADB mode, data roaming, and wireless/mobile data settings are Android-only concepts.
 */
@objc public class SystemModule: NSObject {

    private let plugin: CAPPlugin

    // Matches Cordova's iOS Diagnostic authorization string constants
    private let status_authorized = "authorized"
    private let status_denied = "denied_always"
    private let status_restricted = "restricted"
    private let status_not_determined = "not_determined"

    init(plugin: CAPPlugin) {
        self.plugin = plugin
        super.init()
    }

    /*
     * Opens the app's page in the device Settings app.
     * Uses UIApplication.openSettingsURLString — the standard iOS deep link.
     * Must run on the main thread.
     */
    func switchToSettings(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                call.reject("Failed to build settings URL")
                return
            }

            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    call.resolve()
                } else {
                    call.reject("Failed to open settings")
                }
            }
        }
    }

    /*
     * Returns { value: string } — the current background app refresh authorization status.
     *
     * Possible values (matching Cordova iOS strings):
     * "authorized"   — background refresh is available and allowed
     * "denied_always" — the user explicitly disabled it for this app
     * "restricted"   — parental controls or MDM policy prevents it; user cannot change it
     *
     * Must be read from the main thread since UIApplication is not thread-safe.
     */
    func isBackgroundRefreshAuthorized(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let status = UIApplication.shared.backgroundRefreshStatus

            let result: String
            switch status {
            case .available:
                result = self.status_authorized
            case .denied:
                result = self.status_denied
            case .restricted:
                result = self.status_restricted
            @unknown default:
                result = self.status_not_determined
            }

            call.resolve(["value": result])
        }
    }
}
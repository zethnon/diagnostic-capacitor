import Foundation
import Capacitor
import AVFoundation

/*
 * MicrophoneModule is iOS-only — Android doesn't have a separate microphone
 * permission module in this plugin (RECORD_AUDIO is handled at the manifest level
 * and not surfaced as a diagnostic method on Android).
 *
 * Uses AVAudioSession.sharedInstance().recordPermission for all status checks.
 * Requires NSMicrophoneUsageDescription in Info.plist.
 */
@objc public class MicrophoneModule: NSObject {

    private let plugin: CAPPlugin

    private let authorization_granted = "granted"
    private let authorization_denied = "denied"
    private let authorization_not_determined = "not_determined"

    init(plugin: CAPPlugin) {
        self.plugin = plugin
        super.init()
    }

    /*
     * Returns { value: boolean } — true if microphone permission is currently granted.
     * Quick boolean check — no need to map status strings.
     */
    @objc public func isMicrophoneAuthorized(_ call: CAPPluginCall) {
        let record_permission = AVAudioSession.sharedInstance().recordPermission
        call.resolve(["value": record_permission == .granted])
    }

    /*
     * Returns { value: string } — "granted", "denied", or "not_determined".
     * Reads from AVAudioSession without triggering a prompt.
     */
    @objc public func getMicrophoneAuthorizationStatus(_ call: CAPPluginCall) {
        let status = map_microphone_authorization_status(AVAudioSession.sharedInstance().recordPermission)
        call.resolve(["value": status])
    }

    /*
     * Triggers the microphone permission prompt if not yet determined.
     * Returns { value: boolean } — true if granted after the prompt.
     * If already determined, returns the current state without re-prompting.
     */
    @objc public func requestMicrophoneAuthorization(_ call: CAPPluginCall) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            call.resolve(["value": granted])
        }
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    private func map_microphone_authorization_status(_ permission: AVAudioSession.RecordPermission) -> String {
        switch permission {
        case .granted: return authorization_granted
        case .denied: return authorization_denied
        case .undetermined: return authorization_not_determined
        @unknown default: return authorization_not_determined
        }
    }
}
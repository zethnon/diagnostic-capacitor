import Foundation
import Capacitor
import AVFoundation

@objc public class MicrophoneModule: NSObject {

    private let plugin: CAPPlugin

    private let authorization_granted = "granted"
    private let authorization_denied = "denied"
    private let authorization_not_determined = "not_determined"

    init(plugin: CAPPlugin) {
        self.plugin = plugin
        super.init()
    }

    @objc public func isMicrophoneAuthorized(_ call: CAPPluginCall) {
        let record_permission = AVAudioSession.sharedInstance().recordPermission
        call.resolve([
            "value": record_permission == .granted
        ])
    }

    @objc public func getMicrophoneAuthorizationStatus(_ call: CAPPluginCall) {
        let status = map_microphone_authorization_status(AVAudioSession.sharedInstance().recordPermission)
        call.resolve([
            "value": status
        ])
    }

    @objc public func requestMicrophoneAuthorization(_ call: CAPPluginCall) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            call.resolve([
                "value": granted
            ])
        }
    }

    private func map_microphone_authorization_status(_ permission: AVAudioSession.RecordPermission) -> String {
        switch permission {
        case .granted:
            return authorization_granted
        case .denied:
            return authorization_denied
        case .undetermined:
            return authorization_not_determined
        @unknown default:
            return authorization_not_determined
        }
    }
}
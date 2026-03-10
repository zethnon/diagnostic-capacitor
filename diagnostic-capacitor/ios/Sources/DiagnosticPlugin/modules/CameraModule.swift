import Foundation
import Capacitor
import AVFoundation
import Photos
import UIKit

final class CameraModule {

    private let authorizationDenied = "DENIED"
    private let authorizationGranted = "GRANTED"
    private let authorizationNotRequested = "NOT_REQUESTED"
    private let authorizationLimited = "LIMITED"
    private let unknown = "UNKNOWN"

    private let photoLibraryAccessLevelAddOnly = "add_only"
    private let photoLibraryAccessLevelReadWrite = "read_write"

    func isCameraPresent(_ call: CAPPluginCall) {
        let present = UIImagePickerController.isSourceTypeAvailable(.camera)
        call.resolve([
            "present": present
        ])
    }

    func requestCameraAuthorization(_ call: CAPPluginCall) {
        let storage = call.getBool("storage") ?? false

        AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
            guard let self else { return }

            if storage {
                self.requestPhotoLibraryAuthorization(call)
            } else {
                call.resolve([
                    "status": self.getCameraAuthorizationStatusValue(storage: false)
                ])
            }
        }
    }

    func getCameraAuthorizationStatus(_ call: CAPPluginCall) {
        let storage = call.getBool("storage") ?? false
        let accessLevel = call.getString("accessLevel") ?? photoLibraryAccessLevelAddOnly

        call.resolve([
            "status": getCameraAuthorizationStatusValue(
                storage: storage,
                accessLevelString: accessLevel
            )
        ])
    }

    func getCameraAuthorizationStatuses(_ call: CAPPluginCall) {
        let storage = call.getBool("storage") ?? false
        let accessLevel = call.getString("accessLevel") ?? photoLibraryAccessLevelAddOnly

        call.resolve([
            "statuses": getCameraAuthorizationStatusesValue(
                storage: storage,
                accessLevelString: accessLevel
            )
        ])
    }

    private func requestPhotoLibraryAuthorization(_ call: CAPPluginCall) {
        let accessLevelString = call.getString("accessLevel") ?? photoLibraryAccessLevelAddOnly

        if #available(iOS 14, *) {
            let accessLevel = resolveAccessLevel(from: accessLevelString)
            PHPhotoLibrary.requestAuthorization(for: accessLevel) { [weak self] _ in
                guard let self else { return }
                call.resolve([
                    "status": self.getCameraAuthorizationStatusValue(
                        storage: true,
                        accessLevelString: accessLevelString
                    )
                ])
            }
        } else {
            PHPhotoLibrary.requestAuthorization { [weak self] _ in
                guard let self else { return }
                call.resolve([
                    "status": self.getCameraAuthorizationStatusValue(
                        storage: true,
                        accessLevelString: accessLevelString
                    )
                ])
            }
        }
    }

    private func getCameraAuthorizationStatusValue(
        storage: Bool,
        accessLevelString: String = "add_only"
    ) -> String {
        let cameraStatus = getCameraStatusAsString()

        if !storage {
            return cameraStatus
        }

        let photoStatus = getCameraRollAuthorizationStatusAsString(accessLevelString: accessLevelString)
        return combinePermissionStatuses([cameraStatus, photoStatus])
    }

    private func getCameraAuthorizationStatusesValue(
        storage: Bool,
        accessLevelString: String = "add_only"
    ) -> [String: String] {
        var statuses: [String: String] = [
            "CAMERA": getCameraStatusAsString()
        ]

        if storage {
            statuses["PHOTOLIBRARY"] = getCameraRollAuthorizationStatusAsString(
                accessLevelString: accessLevelString
            )
        }

        return statuses
    }

    private func getCameraStatusAsString() -> String {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch authStatus {
        case .denied, .restricted:
            return authorizationDenied
        case .notDetermined:
            return authorizationNotRequested
        case .authorized:
            return authorizationGranted
        @unknown default:
            return unknown
        }
    }

    private func getCameraRollAuthorizationStatusAsString(accessLevelString: String) -> String {
        let authStatus: PHAuthorizationStatus

        if #available(iOS 14, *) {
            let accessLevel = resolveAccessLevel(from: accessLevelString)
            authStatus = PHPhotoLibrary.authorizationStatus(for: accessLevel)
        } else {
            authStatus = PHPhotoLibrary.authorizationStatus()
        }

        return mapPhotoAuthorizationStatus(authStatus)
    }

    private func mapPhotoAuthorizationStatus(_ authStatus: PHAuthorizationStatus) -> String {
        if #available(iOS 14, *), authStatus == .limited {
            return authorizationLimited
        }

        switch authStatus {
        case .denied, .restricted:
            return authorizationDenied
        case .notDetermined:
            return authorizationNotRequested
        case .authorized:
            return authorizationGranted
        default:
            return unknown
        }
    }

    @available(iOS 14, *)
    private func resolveAccessLevel(from value: String) -> PHAccessLevel {
        if value == photoLibraryAccessLevelReadWrite {
            return .readWrite
        }
        return .addOnly
    }

    private func combinePermissionStatuses(_ statuses: [String]) -> String {
        if statuses.contains("DENIED_ALWAYS") {
            return "DENIED_ALWAYS"
        } else if statuses.contains(authorizationLimited) {
            return authorizationLimited
        } else if statuses.contains(authorizationDenied) {
            return authorizationDenied
        } else if statuses.contains(authorizationGranted) {
            return authorizationGranted
        } else {
            return authorizationNotRequested
        }
    }
}
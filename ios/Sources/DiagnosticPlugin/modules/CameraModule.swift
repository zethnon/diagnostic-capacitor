import Foundation
import Capacitor
import AVFoundation
import Photos
import UIKit

final class CameraModule {

    private let authorizationDenied = "denied"
    private let authorizationGranted = "granted"
    private let authorizationNotRequested = "not_requested"
    private let authorizationLimited = "limited"   // iOS 14+ photo library limited access
    private let unknown = "UNKNOWN"

    private let photoLibraryAccessLevelAddOnly = "add_only"
    private let photoLibraryAccessLevelReadWrite = "read_write"

    /*
     * Returns { present: boolean } — true if the camera UI source type is available.
     * Uses UIImagePickerController.isSourceTypeAvailable which covers the actual
     * hardware availability, not just permission state.
     */
    func isCameraPresent(_ call: CAPPluginCall) {
        let present = UIImagePickerController.isSourceTypeAvailable(.camera)
        call.resolve(["present": present])
    }

    /*
     * Triggers the camera permission prompt. If storage is true, chains into
     * the photo library authorization request after camera resolves.
     *
     * Returns { status: string } — combined camera+storage status if storage=true,
     * or just camera status if storage=false.
     */
    func requestCameraAuthorization(_ call: CAPPluginCall) {
        let storage = call.getBool("storage") ?? false

        AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
            guard let self else { return }

            if storage {
                self.requestPhotoLibraryAuthorization(call)
            } else {
                call.resolve(["status": self.getCameraAuthorizationStatusValue(storage: false)])
            }
        }
    }

    /*
     * Returns { status: string } — current camera (and optionally photo library) status.
     * @param storage — bool, include photo library in the combined status check
     * @param accessLevel — "add_only" | "read_write", only relevant when storage=true on iOS 14+
     */
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

    /*
     * Returns { statuses: { CAMERA, PHOTOLIBRARY } } — individual status per resource.
     * PHOTOLIBRARY only included if storage=true.
     */
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

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    /*
     * Requests photo library access after camera was already approved.
     * iOS 14+ supports per-access-level authorization (addOnly vs readWrite).
     * Pre-iOS 14 only has a single requestAuthorization path.
     */
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

    /*
     * Combines camera + photo library statuses into one value.
     * Without storage: returns camera status directly.
     * With storage: combinePermissionStatuses([camera, photo]) — worst state wins.
     */
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
        var statuses: [String: String] = ["CAMERA": getCameraStatusAsString()]

        if storage {
            statuses["PHOTOLIBRARY"] = getCameraRollAuthorizationStatusAsString(
                accessLevelString: accessLevelString
            )
        }

        return statuses
    }

    /*
     * Maps AVCaptureDevice authorization status to Cordova-compatible strings.
     */
    private func getCameraStatusAsString() -> String {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch authStatus {
        case .denied, .restricted: return authorizationDenied
        case .notDetermined: return authorizationNotRequested
        case .authorized: return authorizationGranted
        @unknown default: return unknown
        }
    }

    /*
     * Maps PHPhotoLibrary authorization status to Cordova-compatible strings.
     * iOS 14+ introduced PHAuthorizationStatus.limited (user selected specific photos).
     * On iOS 14+, the access level (addOnly vs readWrite) affects which status is returned.
     */
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
        case .denied, .restricted: return authorizationDenied
        case .notDetermined: return authorizationNotRequested
        case .authorized: return authorizationGranted
        default: return unknown
        }
    }

    @available(iOS 14, *)
    private func resolveAccessLevel(from value: String) -> PHAccessLevel {
        if value == photoLibraryAccessLevelReadWrite {
            return .readWrite
        }
        return .addOnly
    }

    /*
     * Combines multiple statuses into one.
     * Priority: denied_always > limited > denied > granted > not_requested.
     */
    private func combinePermissionStatuses(_ statuses: [String]) -> String {
        if statuses.contains("denied_always") { return "denied_always" }
        else if statuses.contains(authorizationLimited) { return authorizationLimited }
        else if statuses.contains(authorizationDenied) { return authorizationDenied }
        else if statuses.contains(authorizationGranted) { return authorizationGranted }
        else { return authorizationNotRequested }
    }
}
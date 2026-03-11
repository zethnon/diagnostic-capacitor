#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

CAP_PLUGIN(DiagnosticPlugin, "DiagnosticPlugin",
    // -----------------------
    // Location
    // -----------------------
    CAP_PLUGIN_METHOD(getLocationAuthorizationStatus, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(requestLocationAuthorization, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(openLocationSettings, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(switchToLocationSettings, CAPPluginReturnPromise);

    CAP_PLUGIN_METHOD(isLocationEnabled, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(isLocationAvailable, CAPPluginReturnPromise);

    CAP_PLUGIN_METHOD(isGpsLocationEnabled, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(isNetworkLocationEnabled, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(isGpsLocationAvailable, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(isNetworkLocationAvailable, CAPPluginReturnPromise);

    CAP_PLUGIN_METHOD(getLocationMode, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(isCompassAvailable, CAPPluginReturnPromise);

    CAP_PLUGIN_METHOD(isLocationAuthorized, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getLocationAccuracyAuthorization, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(requestTemporaryFullAccuracyAuthorization, CAPPluginReturnPromise);
    // -----------------------
    // Bluetooth
    // -----------------------
    CAP_PLUGIN_METHOD(switchToBluetoothSettings, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(isBluetoothAvailable, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(isBluetoothEnabled, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(hasBluetoothSupport, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(hasBluetoothLESupport, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(hasBluetoothLEPeripheralSupport, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(setBluetoothState, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getBluetoothState, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getBluetoothAuthorizationStatuses, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(requestBluetoothAuthorization, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(ensureBluetoothManager, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getBluetoothAuthorizationStatus, CAPPluginReturnPromise);
    // -----------------------
    // Camera
    // -----------------------
    CAP_PLUGIN_METHOD(isCameraPresent, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(requestCameraAuthorization, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getCameraAuthorizationStatus, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getCameraAuthorizationStatuses, CAPPluginReturnPromise);
    // -----------------------
    // Notifications
    // -----------------------
    CAP_PLUGIN_METHOD(isRemoteNotificationsEnabled, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getRemoteNotificationTypes, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(isRegisteredForRemoteNotifications, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getRemoteNotificationsAuthorizationStatus, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(requestRemoteNotificationsAuthorization, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(switchToNotificationSettings, CAPPluginReturnPromise);
)
package com.noesis.diagnostic;

import android.Manifest;
import android.os.Build;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.annotation.Permission;
import com.getcapacitor.annotation.PermissionCallback;

import com.noesis.diagnostic.modules.BluetoothModule;
import com.noesis.diagnostic.modules.CameraModule;
import com.noesis.diagnostic.modules.LocationModule;
import com.noesis.diagnostic.modules.NotificationsModule;
import com.noesis.diagnostic.modules.WifiModule;

@CapacitorPlugin(
    name = "DiagnosticPlugin",
    permissions = {
        @Permission(
            alias = "location",
            strings = {
                Manifest.permission.ACCESS_COARSE_LOCATION,
                Manifest.permission.ACCESS_FINE_LOCATION
            }
        ),
        @Permission(
            alias = "backgroundLocation",
            strings = {
                Manifest.permission.ACCESS_BACKGROUND_LOCATION
            }
        ),
        @Permission(
            alias = "bluetooth",
            strings = {
                Manifest.permission.BLUETOOTH_ADVERTISE,
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_SCAN
            }
        ),
        @Permission(
            alias = "camera",
            strings = {
                Manifest.permission.CAMERA
            }
        ),
        @Permission(
            alias = "cameraStorageLegacy",
            strings = {
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
            }
        ),
        @Permission(
            alias = "cameraStorage33",
            strings = {
                Manifest.permission.READ_MEDIA_IMAGES,
                Manifest.permission.READ_MEDIA_VIDEO
            }
        ),
        @Permission(
            alias = "cameraStorage34",
            strings = {
                Manifest.permission.READ_MEDIA_IMAGES,
                Manifest.permission.READ_MEDIA_VIDEO,
                Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED
            }
        ),
        @Permission(
            alias = "notifications",
            strings = {
                Manifest.permission.POST_NOTIFICATIONS
            }
        )
    }
)
public class DiagnosticPlugin extends Plugin implements BluetoothModule.BluetoothEventEmitter {

    private LocationModule location;
    private BluetoothModule bluetooth;
    private CameraModule cameraModule;
    private NotificationsModule notifications;
    private WifiModule wifi;

     @Override
    public void load() {
        super.load();

        location = new LocationModule(this);
        bluetooth = new BluetoothModule(this, this);
        cameraModule = new CameraModule(getContext());
        notifications = new NotificationsModule(this);
        wifi = new WifiModule(this);

        bluetooth.load();
    }

    @Override
    protected void handleOnDestroy() {
        if (bluetooth != null) {
            bluetooth.handleOnDestroy();
        }
        super.handleOnDestroy();
    }

    @Override
    public void emitBluetoothStateChange(String state) {
        JSObject data = new JSObject();
        data.put("state", state);
        notifyListeners("bluetoothStateChange", data);
    }

    // -----------------------
    // Location
    // -----------------------

    @PluginMethod
    public void requestLocationAuthorization(PluginCall call) {
        location.setLocationEverAsked();
        call.getData().put("mode", call.getString("mode", "when_in_use"));
        requestPermissionForAlias("location", call, "onLocationPermissionResult");
    }

    @PluginMethod
    public void getLocationAuthorizationStatus(PluginCall call) {
        location.getLocationAuthorizationStatus(call);
    }

    @PluginMethod
    public void isLocationAvailable(PluginCall call) {
        location.isLocationAvailable(call);
    }

    @PluginMethod
    public void isLocationEnabled(PluginCall call) {
        location.isLocationEnabled(call);
    }

    @PluginMethod
    public void openLocationSettings(PluginCall call) {
        location.openLocationSettings(call);
    }

    @PluginMethod
    public void getLocationMode(PluginCall call) {
        location.getLocationMode(call);
    }

    @PluginMethod
    public void isGpsLocationEnabled(PluginCall call) {
        location.isGpsLocationEnabled(call);
    }

    @PluginMethod
    public void isNetworkLocationEnabled(PluginCall call) {
        location.isNetworkLocationEnabled(call);
    }

    @PluginMethod
    public void isGpsLocationAvailable(PluginCall call) {
        location.isGpsLocationAvailable(call);
    }

    @PluginMethod
    public void isNetworkLocationAvailable(PluginCall call) {
        location.isNetworkLocationAvailable(call);
    }

    @PluginMethod
    public void switchToLocationSettings(PluginCall call) {
        location.switchToLocationSettings(call);
    }

    @PluginMethod
    public void isCompassAvailable(PluginCall call) {
        location.isCompassAvailable(call);
    }

    @PluginMethod
    public void isLocationAuthorized(PluginCall call) {
        location.isLocationAuthorized(call);
    }

    @PluginMethod
    public void getLocationAccuracyAuthorization(PluginCall call) {
        location.getLocationAccuracyAuthorization(call);
    }

    @PluginMethod
    public void requestTemporaryFullAccuracyAuthorization(PluginCall call) {
        location.requestTemporaryFullAccuracyAuthorization(call);
    }

    @PermissionCallback
    private void onLocationPermissionResult(PluginCall call) {
        location.onLocationPermissionResult(call);

        String mode = call.getData().optString("mode", "when_in_use");
        if ("always".equalsIgnoreCase(mode) && Build.VERSION.SDK_INT == Build.VERSION_CODES.Q) {
            requestPermissionForAlias("backgroundLocation", call, "onBackgroundLocationPermissionResult");
        }
    }

    @PermissionCallback
    private void onBackgroundLocationPermissionResult(PluginCall call) {
        location.onBackgroundLocationPermissionResult(call);
    }

    // -----------------------
    // Bluetooth
    // -----------------------

    @PluginMethod
    public void switchToBluetoothSettings(PluginCall call) {
        bluetooth.switchToBluetoothSettings(call);
    }

    @PluginMethod
    public void isBluetoothAvailable(PluginCall call) {
        bluetooth.isBluetoothAvailable(call);
    }

    @PluginMethod
    public void isBluetoothEnabled(PluginCall call) {
        bluetooth.isBluetoothEnabled(call);
    }

    @PluginMethod
    public void hasBluetoothSupport(PluginCall call) {
        bluetooth.hasBluetoothSupport(call);
    }

    @PluginMethod
    public void hasBluetoothLESupport(PluginCall call) {
        bluetooth.hasBluetoothLESupport(call);
    }

    @PluginMethod
    public void hasBluetoothLEPeripheralSupport(PluginCall call) {
        bluetooth.hasBluetoothLEPeripheralSupport(call);
    }

    @PluginMethod
    public void setBluetoothState(PluginCall call) {
        bluetooth.setBluetoothState(call);
    }

    @PluginMethod
    public void getBluetoothState(PluginCall call) {
        bluetooth.getBluetoothState(call);
    }

    @PluginMethod
    public void getBluetoothAuthorizationStatuses(PluginCall call) {
        bluetooth.getBluetoothAuthorizationStatuses(call);
    }

    @PluginMethod
    public void requestBluetoothAuthorization(PluginCall call) {
        bluetooth.requestBluetoothAuthorization(call);
    }

    @PluginMethod
    public void ensureBluetoothManager(PluginCall call) {
        bluetooth.ensureBluetoothManager(call);
    }

    @PluginMethod
    public void getBluetoothAuthorizationStatus(PluginCall call) {
        bluetooth.getBluetoothAuthorizationStatus(call);
    }

    @PermissionCallback
    private void onBluetoothPermissionResult(PluginCall call) {
        bluetooth.onBluetoothPermissionResult(call);
    }

    public void requestBluetoothPermissions(PluginCall call) {
        requestPermissionForAlias("bluetooth", call, "onBluetoothPermissionResult");
    }

    // -----------------------
    // Camera
    // -----------------------

    @PluginMethod
    public void isCameraPresent(PluginCall call) {
        JSObject result = new JSObject();
        result.put("present", cameraModule.isCameraPresent());
        call.resolve(result);
    }

    @PluginMethod
    public void getCameraAuthorizationStatuses(PluginCall call) {
        boolean storage = call.getBoolean("storage", false);
        JSObject result = new JSObject();
        result.put("statuses", cameraModule.getCameraAuthorizationStatuses(storage, getActivity()));
        call.resolve(result);
    }

    @PluginMethod
    public void getCameraAuthorizationStatus(PluginCall call) {
        boolean storage = call.getBoolean("storage", false);
        JSObject result = new JSObject();
        result.put("status", cameraModule.getCameraAuthorizationStatus(storage, getActivity()));
        call.resolve(result);
    }

    @PluginMethod
    public void requestCameraAuthorization(PluginCall call) {
        boolean storage = call.getBoolean("storage", false);

        call.getData().put("storage", storage);
        cameraModule.markPermissionsRequested(cameraModule.getPermissions(storage));

        requestPermissionForAlias("camera", call, "onCameraPermissionResult");
    }

    @PermissionCallback
    private void onCameraPermissionResult(PluginCall call) {
        boolean storage = call.getData().optBoolean("storage", false);

        if (!storage) {
            JSObject result = new JSObject();
            result.put("status", cameraModule.getCameraAuthorizationStatus(false, getActivity()));
            call.resolve(result);
            return;
        }

        requestPermissionForAlias(getCameraStorageAlias(), call, "onCameraStoragePermissionResult");
    }

    @PermissionCallback
    private void onCameraStoragePermissionResult(PluginCall call) {
        boolean storage = call.getData().optBoolean("storage", false);

        JSObject result = new JSObject();
        result.put("status", cameraModule.getCameraAuthorizationStatus(storage, getActivity()));
        call.resolve(result);
    }

    private String getCameraStorageAlias() {
        if (Build.VERSION.SDK_INT >= 34) {
            return "cameraStorage34";
        } else if (Build.VERSION.SDK_INT >= 33) {
            return "cameraStorage33";
        } else {
            return "cameraStorageLegacy";
        }
    }

    // -----------------------
    // Notifications
    // -----------------------

    @PluginMethod
    public void isRemoteNotificationsEnabled(PluginCall call) {
        notifications.isRemoteNotificationsEnabled(call);
    }

    @PluginMethod
    public void getRemoteNotificationTypes(PluginCall call) {
        notifications.getRemoteNotificationTypes(call);
    }

    @PluginMethod
    public void isRegisteredForRemoteNotifications(PluginCall call) {
        notifications.isRegisteredForRemoteNotifications(call);
    }

    @PluginMethod
    public void getRemoteNotificationsAuthorizationStatus(PluginCall call) {
        notifications.getRemoteNotificationsAuthorizationStatus(call);
    }

    @PluginMethod
    public void requestRemoteNotificationsAuthorization(PluginCall call) {
        notifications.requestRemoteNotificationsAuthorization(call);
    }

    @PluginMethod
    public void switchToNotificationSettings(PluginCall call) {
        notifications.switchToNotificationSettings(call);
    }

    @PermissionCallback
    private void onNotificationsPermissionResult(PluginCall call) {
        notifications.onNotificationsPermissionResult(call);
    }

    public void requestNotificationsPermission(PluginCall call) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requestPermissionForAlias("notifications", call, "onNotificationsPermissionResult");
        } else {
            notifications.onNotificationsPermissionNotRequired(call);
        }
    }
    
    // -----------------------
    // Wifi
    // -----------------------

    @PluginMethod
    public void switchToWifiSettings(PluginCall call) {
        wifi.switchToWifiSettings(call);
    }

    @PluginMethod
    public void isWifiAvailable(PluginCall call) {
        wifi.isWifiAvailable(call);
    }

    @PluginMethod
    public void isWifiEnabled(PluginCall call) {
        wifi.isWifiEnabled(call);
    }

    @PluginMethod
    public void setWifiState(PluginCall call) {
        wifi.setWifiState(call);
    }
}
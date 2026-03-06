package com.noesis.diagnostic;

import android.Manifest;
import android.annotation.SuppressLint;
import android.bluetooth.BluetoothAdapter;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.os.Build;
import android.provider.Settings;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.annotation.Permission;
import com.getcapacitor.annotation.PermissionCallback;

import com.noesis.diagnostic.modules.LocationModule;

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
        )
    }
)
public class DiagnosticPlugin extends Plugin {

    // -----------------------
    // Location
    // -----------------------

    private LocationModule location;

    // -----------------------
    // Bluetooth constants
    // -----------------------

    private static final String BLUETOOTH_STATE_UNKNOWN = "unknown";
    private static final String BLUETOOTH_STATE_POWERED_ON = "powered_on";
    private static final String BLUETOOTH_STATE_POWERED_OFF = "powered_off";
    private static final String BLUETOOTH_STATE_POWERING_ON = "powering_on";
    private static final String BLUETOOTH_STATE_POWERING_OFF = "powering_off";

    private static final String STATUS_GRANTED = "granted";
    private static final String STATUS_DENIED = "denied";
    private static final String STATUS_DENIED_ALWAYS = "denied_always";
    private static final String STATUS_NOT_DETERMINED = "not_determined";

    private static final String[] BLUETOOTH_PERMISSION_NAMES = new String[] {
        "BLUETOOTH_ADVERTISE",
        "BLUETOOTH_CONNECT",
        "BLUETOOTH_SCAN"
    };

    private String current_bluetooth_state;

    private final BroadcastReceiver bluetooth_state_change_receiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (intent != null && BluetoothAdapter.ACTION_STATE_CHANGED.equals(intent.getAction())) {
                notifyBluetoothStateChange();
            }
        }
    };

    @Override
    public void load() {
        super.load();

        location = new LocationModule(this);

        try {
            getContext().registerReceiver(
                bluetooth_state_change_receiver,
                new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
            );
            current_bluetooth_state = getBluetoothStateValue();
        } catch (Exception ignored) {
        }
    }

    @Override
    protected void handleOnDestroy() {
        try {
            getContext().unregisterReceiver(bluetooth_state_change_receiver);
        } catch (Exception ignored) {
        }
        super.handleOnDestroy();
    }

    // -----------------------
    // Location API
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

    // -----------------------
    // Bluetooth API
    // -----------------------

    @PluginMethod
    public void switchToBluetoothSettings(PluginCall call) {
        try {
            Intent settings_intent = new Intent(Settings.ACTION_BLUETOOTH_SETTINGS);
            settings_intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            getContext().startActivity(settings_intent);
            call.resolve();
        } catch (Exception e) {
            call.reject("Failed to open Bluetooth settings: " + e.getMessage());
        }
    }

    @PluginMethod
    public void isBluetoothAvailable(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("available", hasBluetoothSupportValue() && isBluetoothEnabledValue());
        call.resolve(ret);
    }

    @PluginMethod
    public void isBluetoothEnabled(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("enabled", isBluetoothEnabledValue());
        call.resolve(ret);
    }

    @PluginMethod
    public void hasBluetoothSupport(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("supported", hasBluetoothSupportValue());
        call.resolve(ret);
    }

    @PluginMethod
    public void hasBluetoothLESupport(PluginCall call) {
        PackageManager pm = getActivity().getPackageManager();
        JSObject ret = new JSObject();
        ret.put("supported", pm.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE));
        call.resolve(ret);
    }

    @PluginMethod
    public void hasBluetoothLEPeripheralSupport(PluginCall call) {
        BluetoothAdapter bluetooth_adapter = BluetoothAdapter.getDefaultAdapter();
        JSObject ret = new JSObject();
        ret.put("supported", bluetooth_adapter != null && bluetooth_adapter.isMultipleAdvertisementSupported());
        call.resolve(ret);
    }

    @SuppressLint("MissingPermission")
    @PluginMethod
    public void setBluetoothState(PluginCall call) {
        boolean enable = call.getBoolean("enable", false);

        if (!hasBluetoothSupportValue()) {
            call.reject("Cannot change Bluetooth state as device does not support Bluetooth");
            return;
        }

        if (Build.VERSION.SDK_INT >= 33) {
            call.reject("Cannot change Bluetooth state on Android 13+ as this is no longer supported");
            return;
        }

        JSObject statuses = getBluetoothAuthorizationStatusesValue();
        String bluetooth_connect_status = statuses.getString("BLUETOOTH_CONNECT");

        if (!STATUS_GRANTED.equals(bluetooth_connect_status)) {
            call.reject("Cannot change Bluetooth state as permission is denied");
            return;
        }

        BluetoothAdapter bluetooth_adapter = BluetoothAdapter.getDefaultAdapter();
        if (bluetooth_adapter == null) {
            call.reject("Bluetooth adapter unavailable or not found");
            return;
        }

        try {
            boolean is_enabled = bluetooth_adapter.isEnabled();

            if (enable && !is_enabled) {
                bluetooth_adapter.enable();
            } else if (!enable && is_enabled) {
                bluetooth_adapter.disable();
            }

            call.resolve();
        } catch (Exception e) {
            call.reject("Failed to change Bluetooth state: " + e.getMessage());
        }
    }

    @PluginMethod
    public void getBluetoothState(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("state", getBluetoothStateValue());
        call.resolve(ret);
    }

    @PluginMethod
    public void getBluetoothAuthorizationStatuses(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("statuses", getBluetoothAuthorizationStatusesValue());
        call.resolve(ret);
    }

    @PluginMethod
    public void requestBluetoothAuthorization(PluginCall call) {
        if (Build.VERSION.SDK_INT < 31) {
            JSObject ret = new JSObject();
            ret.put("status", STATUS_GRANTED);
            call.resolve(ret);
            return;
        }

        requestPermissionForAlias("bluetooth", call, "onBluetoothPermissionResult");
    }

    @PermissionCallback
    private void onBluetoothPermissionResult(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("status", getBluetoothAuthorizationStatusValue());
        call.resolve(ret);
    }

    @PluginMethod
    public void ensureBluetoothManager(PluginCall call) {
        call.resolve();
    }

    @PluginMethod
    public void getBluetoothAuthorizationStatus(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("status", getBluetoothAuthorizationStatusValue());
        call.resolve(ret);
    }

    // -----------------------
    // Bluetooth internals
    // -----------------------

    private boolean isBluetoothEnabledValue() {
        BluetoothAdapter bluetooth_adapter = BluetoothAdapter.getDefaultAdapter();
        return bluetooth_adapter != null && bluetooth_adapter.isEnabled();
    }

    private boolean hasBluetoothSupportValue() {
        PackageManager pm = getActivity().getPackageManager();
        return pm.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH);
    }

    private String getBluetoothStateValue() {
        if (!hasBluetoothSupportValue()) {
            return BLUETOOTH_STATE_UNKNOWN;
        }

        BluetoothAdapter bluetooth_adapter = BluetoothAdapter.getDefaultAdapter();
        if (bluetooth_adapter == null) {
            return BLUETOOTH_STATE_UNKNOWN;
        }

        switch (bluetooth_adapter.getState()) {
            case BluetoothAdapter.STATE_OFF:
                return BLUETOOTH_STATE_POWERED_OFF;
            case BluetoothAdapter.STATE_ON:
                return BLUETOOTH_STATE_POWERED_ON;
            case BluetoothAdapter.STATE_TURNING_OFF:
                return BLUETOOTH_STATE_POWERING_OFF;
            case BluetoothAdapter.STATE_TURNING_ON:
                return BLUETOOTH_STATE_POWERING_ON;
            default:
                return BLUETOOTH_STATE_UNKNOWN;
        }
    }

    private void notifyBluetoothStateChange() {
        try {
            String new_state = getBluetoothStateValue();
            if (current_bluetooth_state == null || !current_bluetooth_state.equals(new_state)) {
                current_bluetooth_state = new_state;

                JSObject data = new JSObject();
                data.put("state", new_state);
                notifyListeners("bluetoothStateChange", data);
            }
        } catch (Exception ignored) {
        }
    }

    private JSObject getBluetoothAuthorizationStatusesValue() {
        JSObject statuses = new JSObject();

        if (Build.VERSION.SDK_INT >= 31) {
            statuses.put(
                "BLUETOOTH_ADVERTISE",
                getPermissionStatusForManifestPermission(Manifest.permission.BLUETOOTH_ADVERTISE)
            );
            statuses.put(
                "BLUETOOTH_CONNECT",
                getPermissionStatusForManifestPermission(Manifest.permission.BLUETOOTH_CONNECT)
            );
            statuses.put(
                "BLUETOOTH_SCAN",
                getPermissionStatusForManifestPermission(Manifest.permission.BLUETOOTH_SCAN)
            );
        } else {
            boolean has_manifest_permission = hasLegacyBluetoothManifestPermission();
            String status = has_manifest_permission ? STATUS_GRANTED : STATUS_DENIED_ALWAYS;

            for (String permission_name : BLUETOOTH_PERMISSION_NAMES) {
                statuses.put(permission_name, status);
            }
        }

        return statuses;
    }

    private String getBluetoothAuthorizationStatusValue() {
        if (Build.VERSION.SDK_INT < 31) {
            return STATUS_GRANTED;
        }

        JSObject statuses = getBluetoothAuthorizationStatusesValue();
        boolean any_denied_always = false;
        boolean any_denied = false;
        boolean any_not_determined = false;

        for (String permission_name : BLUETOOTH_PERMISSION_NAMES) {
            String value = statuses.getString(permission_name);

            if (STATUS_DENIED_ALWAYS.equals(value)) {
                any_denied_always = true;
            } else if (STATUS_DENIED.equals(value)) {
                any_denied = true;
            } else if (STATUS_NOT_DETERMINED.equals(value)) {
                any_not_determined = true;
            }
        }

        if (any_denied_always) {
            return STATUS_DENIED_ALWAYS;
        }
        if (any_denied) {
            return STATUS_DENIED;
        }
        if (any_not_determined) {
            return STATUS_NOT_DETERMINED;
        }

        return STATUS_GRANTED;
    }

    private String getPermissionStatusForManifestPermission(String permission) {
        if (Build.VERSION.SDK_INT < 23) {
            return STATUS_GRANTED;
        }

        int check = ContextCompat.checkSelfPermission(getContext(), permission);
        if (check == PackageManager.PERMISSION_GRANTED) {
            return STATUS_GRANTED;
        }

        if (getActivity() != null) {
            boolean should_show_rationale =
                ActivityCompat.shouldShowRequestPermissionRationale(getActivity(), permission);

            if (should_show_rationale) {
                return STATUS_DENIED;
            }
        }

        return STATUS_DENIED_ALWAYS;
    }

    private boolean hasLegacyBluetoothManifestPermission() {
        Context context = getContext();

        return context.checkCallingOrSelfPermission(Manifest.permission.BLUETOOTH) == PackageManager.PERMISSION_GRANTED
            || context.checkCallingOrSelfPermission(Manifest.permission.BLUETOOTH_ADMIN) == PackageManager.PERMISSION_GRANTED;
    }
}
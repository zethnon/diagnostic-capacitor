package com.noesis.diagnostic.modules;

import android.Manifest;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.hardware.Sensor;
import android.hardware.SensorManager;
import android.location.LocationManager;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.util.Log;

import androidx.core.content.ContextCompat;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;

public class LocationModule {

    /*
     * Interface implemented by DiagnosticPlugin to forward location state
     * change events to the JS layer via notifyListeners().
     * Same pattern as BluetoothEventEmitter and NfcStateChangeEmitter.
     */
    public interface LocationStateChangeEmitter {
        void emitLocationStateChange(String state);
    }

    private static final String TAG = "DiagCap";
    private static final String PREFS = "DiagCapPrefs";
    private static final String KEY_LOC_ASKED = "loc_asked";

    private final Plugin plugin;
    private final LocationStateChangeEmitter emitter;

    private String current_location_state = null;
    private boolean receiver_registered = false;

    public LocationModule(Plugin plugin, LocationStateChangeEmitter emitter) {
        this.plugin = plugin;
        this.emitter = emitter;
    }

    /*
     * BroadcastReceiver for PROVIDERS_CHANGED_ACTION.
     * Fires when the user toggles GPS or network location in Settings.
     */
    private final BroadcastReceiver location_state_change_receiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (intent != null && LocationManager.PROVIDERS_CHANGED_ACTION.equals(intent.getAction())) {
                notifyLocationStateChange();
            }
        }
    };

    /*
     * Called from DiagnosticPlugin.load().
     * Registers the PROVIDERS_CHANGED_ACTION receiver and captures initial state.
     */
    public void load() {
        Log.d(TAG, "LocationModule.load()");
        try {
            plugin.getContext().registerReceiver(
                location_state_change_receiver,
                new IntentFilter(LocationManager.PROVIDERS_CHANGED_ACTION)
            );
            receiver_registered = true;
            current_location_state = getLocationStateValue();
        } catch (Exception e) {
            Log.d(TAG, "LocationModule.load() registerReceiver failed: " + e.getMessage());
        }
    }

    /*
     * Called from DiagnosticPlugin.handleOnDestroy().
     */
    public void destroy() {
        if (!receiver_registered) return;
        try {
            plugin.getContext().unregisterReceiver(location_state_change_receiver);
            receiver_registered = false;
        } catch (Exception ignored) {}
    }

    // -------------------------------------------------------------------------
    // State change internals
    // -------------------------------------------------------------------------

    /*
     * Maps the current provider state to a Cordova-compatible location mode string.
     * These match the strings returned by getLocationMode() for consistency.
     */
    private String getLocationStateValue() {
        try {
            int mode = getLocationModeInt();
            switch (mode) {
                case 3: return "high_accuracy";
                case 1: return "device_only";
                case 2: return "battery_saving";
                default: return "location_off";
            }
        } catch (Exception e) {
            return "location_off";
        }
    }

    /*
     * Deduplicates location state change events — only fires the emitter
     * if the state actually changed from the last known value.
     */
    private void notifyLocationStateChange() {
        try {
            String new_state = getLocationStateValue();
            if (current_location_state == null || !current_location_state.equals(new_state)) {
                current_location_state = new_state;
                if (emitter != null) {
                    emitter.emitLocationStateChange(new_state);
                }
            }
        } catch (Exception ignored) {}
    }

    // -------------------------------------------------------------------------
    // Plugin methods
    // -------------------------------------------------------------------------

    private Context getContext() {
        return plugin.getContext();
    }

    private boolean wasLocationEverAsked() {
        SharedPreferences sp = getContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        return sp.getBoolean(KEY_LOC_ASKED, false);
    }

    public void setLocationEverAsked() {
        SharedPreferences sp = getContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        sp.edit().putBoolean(KEY_LOC_ASKED, true).apply();
    }

    /*
     * Returns the full authorization status string matching Cordova:
     * "authorized_always", "authorized_when_in_use", "denied", "not_determined".
     */
    public void getLocationAuthorizationStatus(PluginCall call) {
        boolean fineGranted =
            ContextCompat.checkSelfPermission(getContext(), Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
        boolean coarseGranted =
            ContextCompat.checkSelfPermission(getContext(), Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED;
        boolean foregroundGranted = fineGranted || coarseGranted;

        boolean backgroundGranted = false;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            backgroundGranted =
                ContextCompat.checkSelfPermission(getContext(), Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED;
        }

        JSObject ret = new JSObject();
        if (backgroundGranted) {
            ret.put("status", "authorized_always");
        } else if (foregroundGranted) {
            ret.put("status", "authorized_when_in_use");
        } else {
            ret.put("status", wasLocationEverAsked() ? "denied" : "not_determined");
        }

        Log.d(TAG, "getLocationAuthorizationStatus -> " + ret.getString("status"));
        call.resolve(ret);
    }

    /*
     * Returns { available: boolean } — system provider is on AND app has foreground permission.
     */
    public void isLocationAvailable(PluginCall call) {
        boolean available = false;
        try {
            int mode = getLocationModeInt();
            boolean enabled = (mode != 0);
            boolean authorized = isLocationAuthorizedForeground();
            available = enabled && authorized;
        } catch (Exception ignored) {}

        JSObject ret = new JSObject();
        ret.put("available", available);
        Log.d(TAG, "isLocationAvailable -> " + available);
        call.resolve(ret);
    }

    /*
     * Returns { enabled: boolean } — system location provider state only.
     */
    public void isLocationEnabled(PluginCall call) {
        boolean enabled = false;
        try {
            int mode = getLocationModeInt();
            enabled = (mode != 0);
        } catch (Exception ignored) {}

        JSObject ret = new JSObject();
        ret.put("enabled", enabled);
        Log.d(TAG, "isLocationEnabled -> " + enabled);
        call.resolve(ret);
    }

    /*
     * Opens the app's detail settings page.
     */
    public void openLocationSettings(PluginCall call) {
        Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
        Uri uri = Uri.fromParts("package", getContext().getPackageName(), null);
        intent.setData(uri);

        if (plugin.getActivity() != null) {
            plugin.getActivity().startActivity(intent);
        } else {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            getContext().startActivity(intent);
        }
        call.resolve();
    }

    /*
     * Returns { mode: string } — "high_accuracy", "device_only", "battery_saving",
     * "location_off", or "unknown".
     */
    public void getLocationMode(PluginCall call) {
        String modeName = "unknown";
        try {
            int mode = getLocationModeInt();
            modeName = switch (mode) {
                case 3 -> "high_accuracy";
                case 1 -> "device_only";
                case 2 -> "battery_saving";
                case 0 -> "location_off";
                default -> "unknown";
            };
        } catch (Exception ignored) {}

        JSObject ret = new JSObject();
        ret.put("mode", modeName);
        Log.d(TAG, "getLocationMode -> " + modeName);
        call.resolve(ret);
    }

    /*
     * Returns { enabled: boolean } — GPS provider active (mode 3 or 1).
     */
    public void isGpsLocationEnabled(PluginCall call) {
        boolean enabled = false;
        try {
            int mode = getLocationModeInt();
            enabled = (mode == 3 || mode == 1);
        } catch (Exception ignored) {}

        JSObject ret = new JSObject();
        ret.put("enabled", enabled);
        Log.d(TAG, "isGpsLocationEnabled -> " + enabled);
        call.resolve(ret);
    }

    /*
     * Returns { enabled: boolean } — network provider active (mode 3 or 2).
     */
    public void isNetworkLocationEnabled(PluginCall call) {
        boolean enabled = false;
        try {
            int mode = getLocationModeInt();
            enabled = (mode == 3 || mode == 2);
        } catch (Exception ignored) {}

        JSObject ret = new JSObject();
        ret.put("enabled", enabled);
        Log.d(TAG, "isNetworkLocationEnabled -> " + enabled);
        call.resolve(ret);
    }

    /*
     * Returns { available: boolean } — GPS enabled AND foreground permission granted.
     */
    public void isGpsLocationAvailable(PluginCall call) {
        boolean available = false;
        try {
            int mode = getLocationModeInt();
            boolean gpsEnabled = (mode == 3 || mode == 1);
            boolean authorized = isLocationAuthorizedForeground();
            available = gpsEnabled && authorized;
        } catch (Exception ignored) {}

        JSObject ret = new JSObject();
        ret.put("available", available);
        Log.d(TAG, "isGpsLocationAvailable -> " + available);
        call.resolve(ret);
    }

    /*
     * Returns { available: boolean } — network location enabled AND foreground permission granted.
     */
    public void isNetworkLocationAvailable(PluginCall call) {
        boolean available = false;
        try {
            int mode = getLocationModeInt();
            boolean netEnabled = (mode == 3 || mode == 2);
            boolean authorized = isLocationAuthorizedForeground();
            available = netEnabled && authorized;
        } catch (Exception ignored) {}

        JSObject ret = new JSObject();
        ret.put("available", available);
        Log.d(TAG, "isNetworkLocationAvailable -> " + available);
        call.resolve(ret);
    }

    /*
     * Opens the system location source settings screen (global toggle).
     */
    public void switchToLocationSettings(PluginCall call) {
        Intent intent = new Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS);
        if (plugin.getActivity() != null) {
            plugin.getActivity().startActivity(intent);
        } else {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            getContext().startActivity(intent);
        }
        Log.d(TAG, "switchToLocationSettings -> opened");
        call.resolve();
    }

    /*
     * Returns { available: boolean } — checks for a magnetic field sensor.
     */
    public void isCompassAvailable(PluginCall call) {
        boolean available = false;
        try {
            SensorManager sm = (SensorManager) getContext().getSystemService(Context.SENSOR_SERVICE);
            available = (sm != null && sm.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD) != null);
        } catch (Exception ignored) {}

        JSObject ret = new JSObject();
        ret.put("available", available);
        Log.d(TAG, "isCompassAvailable -> " + available);
        call.resolve(ret);
    }

    /*
     * Returns { value: boolean } — true if fine or coarse location is granted.
     */
    public void isLocationAuthorized(PluginCall call) {
        boolean authorized = isLocationAuthorizedForeground();
        JSObject ret = new JSObject();
        ret.put("value", authorized);
        Log.d(TAG, "isLocationAuthorized -> " + authorized);
        call.resolve(ret);
    }

    /*
     * Returns { value: "full" } always on Android.
     * Reduced accuracy is an iOS 14+ concept.
     */
    public void getLocationAccuracyAuthorization(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("value", "full");
        call.resolve(ret);
    }

    /*
     * Returns { value: "full" } always on Android.
     * Temporary accuracy is an iOS 14+ concept.
     */
    public void requestTemporaryFullAccuracyAuthorization(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("value", "full");
        call.resolve(ret);
    }

    public void onLocationPermissionResult(PluginCall call) {
        boolean fineGranted =
            ContextCompat.checkSelfPermission(getContext(), Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
        boolean coarseGranted =
            ContextCompat.checkSelfPermission(getContext(), Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED;
        boolean foregroundGranted = fineGranted || coarseGranted;

        if (!foregroundGranted) {
            JSObject ret = new JSObject();
            ret.put("status", "denied");
            call.resolve(ret);
            return;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            boolean backgroundGranted =
                ContextCompat.checkSelfPermission(getContext(), Manifest.permission.ACCESS_BACKGROUND_LOCATION)
                    == PackageManager.PERMISSION_GRANTED;
            if (backgroundGranted) {
                JSObject ret = new JSObject();
                ret.put("status", "authorized_always");
                call.resolve(ret);
                return;
            }
        }

        String mode = call.getData().optString("mode", "when_in_use");
        if ("always".equalsIgnoreCase(mode) && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            JSObject ret = new JSObject();
            ret.put("status", "authorized_when_in_use");
            call.resolve(ret);
            return;
        }

        JSObject ret = new JSObject();
        ret.put("status", "authorized_when_in_use");
        call.resolve(ret);
    }

    public void onBackgroundLocationPermissionResult(PluginCall call) {
        boolean backgroundGranted = false;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            backgroundGranted =
                ContextCompat.checkSelfPermission(getContext(), Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED;
        }

        JSObject ret = new JSObject();
        ret.put("status", backgroundGranted ? "authorized_always" : "authorized_when_in_use");
        call.resolve(ret);
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    /*
     * Pre-API 28: reads Settings.Secure.LOCATION_MODE.
     * API 28+: reconstructs mode from LocationManager provider state.
     */
    private int getLocationModeInt() throws Exception {
        if (Build.VERSION.SDK_INT < 28) {
            return Settings.Secure.getInt(
                getContext().getContentResolver(),
                Settings.Secure.LOCATION_MODE
            );
        }

        LocationManager lm = (LocationManager) getContext().getSystemService(Context.LOCATION_SERVICE);
        boolean gps = false;
        boolean network = false;

        if (lm != null) {
            try { gps = lm.isProviderEnabled(LocationManager.GPS_PROVIDER); } catch (Exception ignored) {}
            try { network = lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER); } catch (Exception ignored) {}
        }

        if (gps && network) return 3;
        if (gps) return 1;
        if (network) return 2;
        return 0;
    }

    private boolean isLocationAuthorizedForeground() {
        boolean fineGranted =
            ContextCompat.checkSelfPermission(getContext(), Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
        boolean coarseGranted =
            ContextCompat.checkSelfPermission(getContext(), Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED;
        return fineGranted || coarseGranted;
    }
}
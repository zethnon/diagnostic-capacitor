package com.noesis.diagnostic.modules;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
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

    private static final String PREFS = "DiagCapPrefs";
    private static final String KEY_LOC_ASKED = "loc_asked";

    private final Plugin plugin;

    public LocationModule(Plugin plugin) {
        this.plugin = plugin;
    }

    private Context getContext() {
        return plugin.getContext();
    }

    /*
     * Tracks whether the user has ever been asked for location.
     * We persist this ourselves because Android doesn't give us a clean
     * "never asked" vs "denied" distinction — that gap only shows up via
     * shouldShowRequestPermissionRationale(), which is unreliable as a first-read.
     */
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
     *
     * Background location is only tracked on Android Q+. On older versions,
     * foreground grant is the highest state we can reach.
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

        Log.d("DiagCap", "getLocationAuthorizationStatus -> " + ret.getString("status"));
        call.resolve(ret);
    }

    /*
     * Returns { available: boolean }.
     * Location is "available" only if both the system provider is on AND
     * the app has at least foreground permission. Matches Cordova behavior.
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
        Log.d("DiagCap", "isLocationAvailable -> " + available);
        call.resolve(ret);
    }

    /*
     * Returns { enabled: boolean }.
     * Checks only the system location provider — does not factor in app permission.
     */
    public void isLocationEnabled(PluginCall call) {
        boolean enabled = false;

        try {
            int mode = getLocationModeInt();
            enabled = (mode != 0);
        } catch (Exception ignored) {}

        JSObject ret = new JSObject();
        ret.put("enabled", enabled);
        Log.d("DiagCap", "isLocationEnabled -> " + enabled);
        call.resolve(ret);
    }

    /*
     * Opens the app's detail settings page (not the global location settings).
     * This lets the user grant/revoke location permission for this specific app.
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
     * Returns { mode: string } — one of: "high_accuracy", "device_only", "battery_saving", "location_off", "unknown".
     *
     * Pre-API 28 reads Settings.Secure.LOCATION_MODE directly.
     * API 28+ that setting was deprecated — we reconstruct the mode by
     * querying GPS and network providers from LocationManager.
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
        Log.d("DiagCap", "getLocationMode -> " + modeName);
        call.resolve(ret);
    }

    /*
     * Returns { enabled: boolean } — true if GPS provider is active.
     * Mode 3 (high_accuracy) and mode 1 (device_only) both have GPS on.
     */
    public void isGpsLocationEnabled(PluginCall call) {
        boolean enabled = false;

        try {
            int mode = getLocationModeInt();
            enabled = (mode == 3 || mode == 1);
        } catch (Exception ignored) {}

        JSObject ret = new JSObject();
        ret.put("enabled", enabled);
        Log.d("DiagCap", "isGpsLocationEnabled -> " + enabled);
        call.resolve(ret);
    }

    /*
     * Returns { enabled: boolean } — true if network/WiFi location provider is active.
     * Mode 3 (high_accuracy) and mode 2 (battery_saving) both have network on.
     */
    public void isNetworkLocationEnabled(PluginCall call) {
        boolean enabled = false;

        try {
            int mode = getLocationModeInt();
            enabled = (mode == 3 || mode == 2);
        } catch (Exception ignored) {}

        JSObject ret = new JSObject();
        ret.put("enabled", enabled);
        Log.d("DiagCap", "isNetworkLocationEnabled -> " + enabled);
        call.resolve(ret);
    }

    /*
     * Returns { available: boolean } — GPS enabled AND app has foreground permission.
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
        Log.d("DiagCap", "isGpsLocationAvailable -> " + available);
        call.resolve(ret);
    }

    /*
     * Returns { available: boolean } — network location enabled AND app has foreground permission.
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
        Log.d("DiagCap", "isNetworkLocationAvailable -> " + available);
        call.resolve(ret);
    }

    /*
     * Opens the system's location source settings screen.
     * Unlike openLocationSettings, this is the global toggle — not app-specific.
     */
    public void switchToLocationSettings(PluginCall call) {
        Intent intent = new Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS);

        if (plugin.getActivity() != null) {
            plugin.getActivity().startActivity(intent);
        } else {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            getContext().startActivity(intent);
        }

        Log.d("DiagCap", "switchToLocationSettings -> opened");
        call.resolve();
    }

    /*
     * Returns { available: boolean } — checks for a magnetic field sensor (hardware compass).
     * Purely hardware capability check — no permission involved.
     */
    public void isCompassAvailable(PluginCall call) {
        boolean available = false;

        try {
            SensorManager sm = (SensorManager) getContext().getSystemService(Context.SENSOR_SERVICE);
            available = (sm != null && sm.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD) != null);
        } catch (Exception ignored) {}

        JSObject ret = new JSObject();
        ret.put("available", available);
        Log.d("DiagCap", "isCompassAvailable -> " + available);
        call.resolve(ret);
    }

    /*
     * Returns { value: boolean } — true if the app has either fine or coarse location granted.
     * "Authorized" here means foreground only — background is not checked.
     */
    public void isLocationAuthorized(PluginCall call) {
        boolean authorized = isLocationAuthorizedForeground();
        JSObject ret = new JSObject();
        ret.put("value", authorized);
        Log.d("DiagCap", "isLocationAuthorized -> " + authorized);
        call.resolve(ret);
    }

    /*
     * Returns { value: "full" } always on Android.
     * The reduced accuracy concept (iOS 14+) doesn't exist on Android —
     * this is here purely for Cordova API surface parity.
     */
    public void getLocationAccuracyAuthorization(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("value", "full");
        Log.d("DiagCap", "getLocationAccuracyAuthorization -> full");
        call.resolve(ret);
    }

    /*
     * Returns { value: "full" } always on Android.
     * Temporary accuracy downgrade/upgrade is an iOS 14+ concept.
     * Android always runs at full accuracy if permission is granted.
     */
    public void requestTemporaryFullAccuracyAuthorization(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("value", "full");
        Log.d("DiagCap", "requestTemporaryFullAccuracyAuthorization -> full");
        call.resolve(ret);
    }

    /*
     * Called after the Capacitor permission dialog closes for foreground location.
     * On Android Q (10), we have to fire the background location prompt separately
     * if "always" was requested — Android Q requires a second prompt for background.
     * Post-Q, "always" requires the user to manually go to Settings.
     */
    public void onLocationPermissionResult(PluginCall call) {
        boolean fineGranted =
            ContextCompat.checkSelfPermission(getContext(), Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;

        boolean coarseGranted =
            ContextCompat.checkSelfPermission(getContext(), Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED;

        boolean foregroundGranted = fineGranted || coarseGranted;

        if (!foregroundGranted) {
            JSObject ret = new JSObject();
            ret.put("status", "denied");
            Log.d("DiagCap", "onLocationPermissionResult -> " + ret.getString("status"));
            call.resolve(ret);
            return;
        }

        // If background already granted, keep authorized_always regardless of requested mode
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            boolean backgroundGranted =
                ContextCompat.checkSelfPermission(getContext(), Manifest.permission.ACCESS_BACKGROUND_LOCATION)
                    == PackageManager.PERMISSION_GRANTED;

            if (backgroundGranted) {
                JSObject ret = new JSObject();
                ret.put("status", "authorized_always");
                Log.d("DiagCap", "onLocationPermissionResult -> authorized_always (already had background)");
                call.resolve(ret);
                return;
            }
        }

        String mode = call.getData().optString("mode", "when_in_use");

        if ("always".equalsIgnoreCase(mode) && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {

            if (Build.VERSION.SDK_INT == Build.VERSION_CODES.Q) {
                JSObject ret = new JSObject();
                ret.put("status", "authorized_when_in_use");
                Log.d("DiagCap", "onLocationPermissionResult -> " + ret.getString("status") + " (background prompt requested next)");
                call.resolve(ret);
                return;
            }

            JSObject ret = new JSObject();
            ret.put("status", "authorized_when_in_use");
            Log.d("DiagCap", "onLocationPermissionResult -> " + ret.getString("status") + " (settings required for always)");
            call.resolve(ret);
            return;
        }

        JSObject ret = new JSObject();
        ret.put("status", "authorized_when_in_use");
        Log.d("DiagCap", "onLocationPermissionResult -> " + ret.getString("status"));
        call.resolve(ret);
    }

    /*
     * Called after the background location permission prompt closes (Android Q only path).
     * Returns "authorized_always" if background was granted, "authorized_when_in_use" otherwise.
     */
    public void onBackgroundLocationPermissionResult(PluginCall call) {
        boolean backgroundGranted = false;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            backgroundGranted =
                ContextCompat.checkSelfPermission(getContext(), Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED;
        }

        JSObject ret = new JSObject();
        ret.put("status", backgroundGranted ? "authorized_always" : "authorized_when_in_use");
        Log.d("DiagCap", "onBackgroundLocationPermissionResult -> " + ret.getString("status"));
        call.resolve(ret);
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    /*
     * Returns an integer representing the active location mode.
     * Maps to: 0=off, 1=device_only (GPS), 2=battery_saving (network), 3=high_accuracy (GPS+network).
     *
     * Pre-API 28: reads Settings.Secure.LOCATION_MODE directly (deprecated but still works).
     * API 28+: reconstructs mode by querying GPS and network providers from LocationManager.
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
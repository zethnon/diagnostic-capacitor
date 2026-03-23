package com.noesis.diagnostic.modules;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.util.Log;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;

public class SystemModule {

    private static final String TAG = "DiagCap";

    private final Plugin plugin;

    public SystemModule(Plugin plugin) {
        this.plugin = plugin;
    }

    /*
     * Opens the app's own page in the device Settings.
     * This is the standard "go fix your permissions" entry point.
     * Uses ACTION_APPLICATION_DETAILS_SETTINGS with the app's package URI.
     */
    public void switchToSettings(PluginCall call) {
        try {
            Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
            Uri uri = Uri.fromParts("package", plugin.getContext().getPackageName(), null);
            intent.setData(uri);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            plugin.getContext().startActivity(intent);
            call.resolve();
        } catch (Exception e) {
            call.reject("Failed to open settings: " + e.getMessage());
        }
    }

    /*
     * Returns { enabled: boolean } — true if ADB (developer/USB debugging) is enabled.
     *
     * API 17+: reads Settings.Global.ADB_ENABLED.
     * Pre-API 17: reads the deprecated Settings.Secure.ADB_ENABLED.
     * This is a read-only diagnostic — no permission required.
     */
    public void isADBModeEnabled(PluginCall call) {
        try {
            int mode;
            if (Build.VERSION.SDK_INT >= 17) {
                mode = Settings.Global.getInt(
                    plugin.getContext().getContentResolver(),
                    Settings.Global.ADB_ENABLED,
                    0
                );
            } else {
                mode = Settings.Secure.getInt(
                    plugin.getContext().getContentResolver(),
                    Settings.Secure.ADB_ENABLED,
                    0
                );
            }

            JSObject ret = new JSObject();
            ret.put("enabled", mode == 1);
            Log.d(TAG, "isADBModeEnabled -> " + (mode == 1));
            call.resolve(ret);
        } catch (Exception e) {
            call.reject("Failed to check ADB mode: " + e.getMessage());
        }
    }

    /*
     * Returns { enabled: boolean } — true if data roaming is enabled.
     *
     * Only functional on API 32 (Android 12L) and below — on API 33+,
     * Settings.Global.DATA_ROAMING is no longer accessible to third-party apps.
     * Returns false on API 33+ rather than throwing, to match graceful Cordova behavior.
     */
    public void isDataRoamingEnabled(PluginCall call) {
        try {
            JSObject ret = new JSObject();

            if (Build.VERSION.SDK_INT > 32) {
                // DATA_ROAMING setting not accessible on Android 13+
                ret.put("enabled", false);
            } else {
                int roaming = Settings.Global.getInt(
                    plugin.getContext().getContentResolver(),
                    Settings.Global.DATA_ROAMING,
                    0
                );
                ret.put("enabled", roaming == 1);
                Log.d(TAG, "isDataRoamingEnabled -> " + (roaming == 1));
            }

            call.resolve(ret);
        } catch (Exception e) {
            call.reject("Failed to check data roaming: " + e.getMessage());
        }
    }

    /*
     * Restarts the application.
     *
     * @param cold — boolean. If true, does a cold restart (kills and relaunches the process).
     *               If false, does a warm restart (recreates the main Activity only).
     *
     * Cold restart: finishes all activities, starts the launch intent, calls System.exit(0).
     *   The OS relaunches the app automatically. Works on all API levels.
     *
     * Warm restart: calls Activity.recreate() — restarts only the Cordova/Capacitor
     *   WebView activity without killing the process. Faster but doesn't reset native state.
     *
     * Both must run on the UI thread.
     */
    public void restart(PluginCall call) {
        boolean cold = call.getBoolean("cold", false);

        plugin.getActivity().runOnUiThread(() -> {
            try {
                Activity activity = plugin.getActivity();

                if (activity == null) {
                    call.reject("Activity unavailable");
                    return;
                }

                if (cold) {
                    PackageManager pm = activity.getPackageManager();
                    Intent intent = pm.getLaunchIntentForPackage(activity.getPackageName());

                    if (intent == null) {
                        call.reject("Could not get launch intent for package");
                        return;
                    }

                    activity.finishAffinity();
                    activity.startActivity(intent);
                    System.exit(0);
                } else {
                    activity.recreate();
                    call.resolve();
                }
            } catch (Exception e) {
                call.reject("Failed to restart: " + e.getMessage());
            }
        });
    }

    /*
     * Opens the mobile data / roaming settings screen.
     * Uses ACTION_DATA_ROAMING_SETTINGS.
     */
    public void switchToMobileDataSettings(PluginCall call) {
        try {
            Intent intent = new Intent(Settings.ACTION_DATA_ROAMING_SETTINGS);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            plugin.getContext().startActivity(intent);
            call.resolve();
        } catch (Exception e) {
            call.reject("Failed to open mobile data settings: " + e.getMessage());
        }
    }

    /*
     * Opens the wireless settings screen (WiFi, Bluetooth, mobile networks overview).
     * Uses ACTION_WIRELESS_SETTINGS.
     */
    public void switchToWirelessSettings(PluginCall call) {
        try {
            Intent intent = new Intent(Settings.ACTION_WIRELESS_SETTINGS);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            plugin.getContext().startActivity(intent);
            call.resolve();
        } catch (Exception e) {
            call.reject("Failed to open wireless settings: " + e.getMessage());
        }
    }
}
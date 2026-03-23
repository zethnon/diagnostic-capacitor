package com.noesis.diagnostic.modules;

import android.content.Context;
import android.content.Intent;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.provider.Settings;

import com.getcapacitor.JSObject;
import com.getcapacitor.PluginCall;
import com.noesis.diagnostic.DiagnosticPlugin;

public class WifiModule {

    private final Context context;

    public WifiModule(DiagnosticPlugin plugin) {
        this.context = plugin.getContext().getApplicationContext();
    }

    /*
     * Opens the system WiFi settings screen.
     */
    public void switchToWifiSettings(PluginCall call) {
        try {
            Intent intent = new Intent(Settings.ACTION_WIFI_SETTINGS);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
            call.resolve();
        } catch (Exception ex) {
            call.reject(ex.getMessage());
        }
    }

    /*
     * Returns { available: boolean }.
     * On Android, "available" means WiFi is enabled and the radio is on.
     * This mirrors Cordova's isWifiAvailable() which also uses WifiManager.isWifiEnabled().
     */
    public void isWifiAvailable(PluginCall call) {
        try {
            WifiManager wifi_manager = (WifiManager) context.getSystemService(Context.WIFI_SERVICE);
            boolean available = wifi_manager != null && wifi_manager.isWifiEnabled();

            JSObject result = new JSObject();
            result.put("available", available);
            call.resolve(result);
        } catch (Exception ex) {
            call.reject(ex.getMessage());
        }
    }

    /*
     * Returns { enabled: boolean }.
     * On Android, isWifiEnabled and isWifiAvailable check the same thing —
     * WifiManager.isWifiEnabled(). The distinction exists on iOS (where
     * "available" means connected to a network), but on Android we keep
     * both methods for API parity and both use the same check.
     */
    public void isWifiEnabled(PluginCall call) {
        try {
            WifiManager wifi_manager = (WifiManager) context.getSystemService(Context.WIFI_SERVICE);
            boolean enabled = wifi_manager != null && wifi_manager.isWifiEnabled();

            JSObject result = new JSObject();
            result.put("enabled", enabled);
            call.resolve(result);
        } catch (Exception ex) {
            call.reject(ex.getMessage());
        }
    }

    /*
     * Enables or disables WiFi programmatically.
     * This is only possible on Android 9 (Pie) and below — on Android 10+,
     * WifiManager.setWifiEnabled() was restricted and apps can no longer toggle
     * WiFi silently. We reject the call on those versions to match Cordova behavior,
     * which also fails or silently does nothing there.
     *
     * @param enable — boolean, passed as call param
     */
    public void setWifiState(PluginCall call) {
        try {
            boolean enable = call.getBoolean("enable", false);
            WifiManager wifi_manager = (WifiManager) context.getSystemService(Context.WIFI_SERVICE);

            if (wifi_manager == null) {
                call.reject("WifiManager unavailable");
                return;
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                call.reject("Changing WiFi state is not supported on Android 10+");
                return;
            }

            boolean current_state = wifi_manager.isWifiEnabled();
            if (enable && !current_state) {
                boolean success = wifi_manager.setWifiEnabled(true);
                if (!success) { call.reject("Failed to enable WiFi"); return; }
            } else if (!enable && current_state) {
                boolean success = wifi_manager.setWifiEnabled(false);
                if (!success) { call.reject("Failed to disable WiFi"); return; }
            }

            call.resolve();
        } catch (Exception ex) {
            call.reject(ex.getMessage());
        }
    }
}
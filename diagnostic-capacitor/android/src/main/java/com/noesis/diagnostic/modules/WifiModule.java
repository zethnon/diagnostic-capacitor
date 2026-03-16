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

    public void switchToWifiSettings(PluginCall call) {
        try {
            // Cordova parity:
            // The original plugin opens the OS Wi-Fi settings screen using ACTION_WIFI_SETTINGS.
            // We preserve that same observable behavior in Capacitor.
            Intent intent = new Intent(Settings.ACTION_WIFI_SETTINGS);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
            call.resolve();
        } catch (Exception ex) {
            call.reject(ex.getMessage());
        }
    }

    public void isWifiAvailable(PluginCall call) {
        try {
            WifiManager wifi_manager = (WifiManager) context.getSystemService(Context.WIFI_SERVICE);

            // Cordova Android behavior:
            // isWifiAvailable() only checks WifiManager.isWifiEnabled().
            // It does NOT verify active connection to an access point.
            boolean available = wifi_manager != null && wifi_manager.isWifiEnabled();

            JSObject result = new JSObject();
            result.put("available", available);
            call.resolve(result);
        } catch (Exception ex) {
            call.reject(ex.getMessage());
        }
    }

    public void isWifiEnabled(PluginCall call) {
        try {
            WifiManager wifi_manager = (WifiManager) context.getSystemService(Context.WIFI_SERVICE);

            // Added for Capacitor API completeness:
            // On Android this is effectively the same check used by Cordova's isWifiAvailable().
            boolean enabled = wifi_manager != null && wifi_manager.isWifiEnabled();

            JSObject result = new JSObject();
            result.put("enabled", enabled);
            call.resolve(result);
        } catch (Exception ex) {
            call.reject(ex.getMessage());
        }
    }

    public void setWifiState(PluginCall call) {
        try {
            boolean enable = call.getBoolean("enable", false);
            WifiManager wifi_manager = (WifiManager) context.getSystemService(Context.WIFI_SERVICE);

            if (wifi_manager == null) {
                call.reject("WifiManager unavailable");
                return;
            }

            // Important platform limitation:
            // Cordova's original implementation uses WifiManager.setWifiEnabled().
            // That API stopped being usable for normal third-party apps on Android 10+.
            // So exact legacy behavior can only be preserved on older Android versions.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                call.reject("Changing WiFi state is not supported on Android 10+");
                return;
            }

            boolean current_state = wifi_manager.isWifiEnabled();

            // Preserve Cordova intent:
            // Only attempt a state change if the requested state differs from the current state.
            if (enable && !current_state) {
                boolean success = wifi_manager.setWifiEnabled(true);
                if (!success) {
                    call.reject("Failed to enable WiFi");
                    return;
                }
            } else if (!enable && current_state) {
                boolean success = wifi_manager.setWifiEnabled(false);
                if (!success) {
                    call.reject("Failed to disable WiFi");
                    return;
                }
            }

            call.resolve();
        } catch (Exception ex) {
            call.reject(ex.getMessage());
        }
    }
}
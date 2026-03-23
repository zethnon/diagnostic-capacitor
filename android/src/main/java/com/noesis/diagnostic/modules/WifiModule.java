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

            // capacitor only change
            // On Android this is effectively the same check used in cordova in isWifiAvailable().
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
            // cordova implementation uses WifiManager.setWifiEnabled().
            // That API stopped being usable for normal third-party apps on Android 10+ 
            // So exact legacy behavior can only be preserved on older Android versions.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                call.reject("Changing WiFi state is not supported on Android 10+");
                return;
            }

            boolean current_state = wifi_manager.isWifiEnabled();
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
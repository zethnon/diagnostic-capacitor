package com.noesis.diagnostic.modules;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;

import androidx.core.app.ActivityCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.core.content.ContextCompat;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;

public class NotificationsModule {

    private static final String NOTIFICATIONS_PREFS = "DiagnosticNotificationsPrefs";
    private static final String POST_NOTIFICATIONS_PERMISSION = Manifest.permission.POST_NOTIFICATIONS;

    private static final String STATUS_GRANTED = "granted";
    private static final String STATUS_DENIED = "denied";
    private static final String STATUS_DENIED_ALWAYS = "denied_always";
    private static final String STATUS_NOT_DETERMINED = "not_determined";

    private static final String REMOTE_NOTIFICATIONS_ALERT = "alert";
    private static final String REMOTE_NOTIFICATIONS_SOUND = "sound";
    private static final String REMOTE_NOTIFICATIONS_BADGE = "badge";

    private final Plugin plugin;

    public NotificationsModule(Plugin plugin) {
        this.plugin = plugin;
    }

    public void isRemoteNotificationsEnabled(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("enabled", isRemoteNotificationsEnabledValue());
        call.resolve(ret);
    }

    public void getRemoteNotificationTypes(PluginCall call) {
        boolean enabled = isRemoteNotificationsEnabledValue();

        JSObject types = new JSObject();
        types.put(REMOTE_NOTIFICATIONS_ALERT, enabled ? "1" : "0");
        types.put(REMOTE_NOTIFICATIONS_SOUND, enabled ? "1" : "0");
        types.put(REMOTE_NOTIFICATIONS_BADGE, enabled ? "1" : "0");

        JSObject ret = new JSObject();
        ret.put("types", types);
        call.resolve(ret);
    }

    public void isRegisteredForRemoteNotifications(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("registered", isRemoteNotificationsEnabledValue());
        call.resolve(ret);
    }

    public void getRemoteNotificationsAuthorizationStatus(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("status", getNormalizedNotificationsAuthorizationStatus());
        call.resolve(ret);
    }

    public void requestRemoteNotificationsAuthorization(PluginCall call) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            onNotificationsPermissionNotRequired(call);
            return;
        }

        String current_status = getNormalizedNotificationsAuthorizationStatus();
        if (STATUS_GRANTED.equals(current_status)) {
            JSObject ret = new JSObject();
            ret.put("status", STATUS_GRANTED);
            call.resolve(ret);
            return;
        }

        markNotificationsPermissionRequested();

        if (plugin instanceof com.noesis.diagnostic.DiagnosticPlugin) {
            ((com.noesis.diagnostic.DiagnosticPlugin) plugin).requestNotificationsPermission(call);
            return;
        }

        call.reject("Plugin does not support notifications permission requests");
    }

    public void switchToNotificationSettings(PluginCall call) {
        try {
            Context context = plugin.getContext();
            Intent settings_intent = new Intent();

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                settings_intent.setAction(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
                settings_intent.putExtra(Settings.EXTRA_APP_PACKAGE, context.getPackageName());
            } else {
                settings_intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
                settings_intent.setData(Uri.parse("package:" + context.getPackageName()));
            }

            settings_intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(settings_intent);
            call.resolve();
        } catch (Exception e) {
            call.reject("Failed to open notification settings: " + e.getMessage());
        }
    }

    public void onNotificationsPermissionResult(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("status", getNormalizedNotificationsAuthorizationStatus());
        call.resolve(ret);
    }

    public void onNotificationsPermissionNotRequired(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("status", getNormalizedNotificationsAuthorizationStatus());
        call.resolve(ret);
    }

    private boolean isRemoteNotificationsEnabledValue() {
        if (!areAppNotificationsEnabled()) {
            return false;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return STATUS_GRANTED.equals(getRawPostNotificationsPermissionStatus());
        }

        return true;
    }

    private boolean areAppNotificationsEnabled() {
        try {
            return NotificationManagerCompat.from(plugin.getContext()).areNotificationsEnabled();
        } catch (Exception ignored) {
            return false;
        }
    }

    private String getNormalizedNotificationsAuthorizationStatus() {
        if (!areAppNotificationsEnabled()) {
            return STATUS_DENIED;
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return STATUS_GRANTED;
        }

        String raw_status = getRawPostNotificationsPermissionStatus();

        if (STATUS_GRANTED.equals(raw_status)) {
            return STATUS_GRANTED;
        }

        if (STATUS_NOT_DETERMINED.equals(raw_status)) {
            return STATUS_NOT_DETERMINED;
        }

        return STATUS_DENIED;
    }

    private String getRawPostNotificationsPermissionStatus() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return STATUS_GRANTED;
        }

        int check = ContextCompat.checkSelfPermission(plugin.getContext(), POST_NOTIFICATIONS_PERMISSION);
        if (check == PackageManager.PERMISSION_GRANTED) {
            return STATUS_GRANTED;
        }

        if (!wasNotificationsPermissionEverRequested()) {
            return STATUS_NOT_DETERMINED;
        }

        if (plugin.getActivity() != null) {
            boolean should_show_rationale =
                ActivityCompat.shouldShowRequestPermissionRationale(
                    plugin.getActivity(),
                    POST_NOTIFICATIONS_PERMISSION
                );

            if (should_show_rationale) {
                return STATUS_DENIED;
            }
        }

        return STATUS_DENIED_ALWAYS;
    }

    private boolean wasNotificationsPermissionEverRequested() {
        return plugin.getContext()
            .getSharedPreferences(NOTIFICATIONS_PREFS, Context.MODE_PRIVATE)
            .getBoolean("requested_" + POST_NOTIFICATIONS_PERMISSION, false);
    }

    private void markNotificationsPermissionRequested() {
        SharedPreferences.Editor editor =
            plugin.getContext()
                .getApplicationContext()
                .getSharedPreferences(NOTIFICATIONS_PREFS, Context.MODE_PRIVATE)
                .edit();

        editor.putBoolean("requested_" + POST_NOTIFICATIONS_PERMISSION, true);
        editor.apply();
    }
}
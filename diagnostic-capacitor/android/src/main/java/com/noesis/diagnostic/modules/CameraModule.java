package com.noesis.diagnostic.modules;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.hardware.Camera;
import android.os.Build;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.getcapacitor.JSObject;

import org.json.JSONException;
import org.json.JSONObject;

public class CameraModule {

    private static final String PREFS_NAME = "DiagnosticCameraPrefs";
    private static final String REQUESTED_PREFIX = "requested_";

    public static final String CAMERA_PERMISSION = Manifest.permission.CAMERA;

    private final Context context;

    public CameraModule(Context context) {
        this.context = context.getApplicationContext();
    }

    public boolean isCameraPresent() {
        int number_of_cameras = Camera.getNumberOfCameras();
        PackageManager pm = context.getPackageManager();

        final boolean device_has_camera_flag =
                Build.VERSION.SDK_INT >= 32
                        ? pm.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)
                        : pm.hasSystemFeature(PackageManager.FEATURE_CAMERA);

        return device_has_camera_flag && number_of_cameras > 0;
    }

    public String[] getPermissions(boolean storage) {
        if (!storage) {
            return new String[]{ CAMERA_PERMISSION };
        }

        String[] storage_permissions = getStoragePermissions();
        String[] permissions = new String[1 + storage_permissions.length];
        permissions[0] = CAMERA_PERMISSION;
        System.arraycopy(storage_permissions, 0, permissions, 1, storage_permissions.length);
        return permissions;
    }

    public JSObject getCameraAuthorizationStatuses(boolean storage, Activity activity) {
        JSObject statuses = new JSObject();

        String[] permissions = getPermissions(storage);
        for (String permission : permissions) {
            statuses.put(permissionToCordovaName(permission), getPermissionAuthorizationStatus(permission, activity));
        }

        return statuses;
    }

    public String getCameraAuthorizationStatus(boolean storage, Activity activity) {
        JSONObject statuses = getCameraAuthorizationStatuses(storage, activity);

        String camera_status = getStatusForPermission(statuses, permissionToCordovaName(CAMERA_PERMISSION));

        if (!storage) {
            return camera_status;
        }

        String storage_status;

        if (
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                (
                        "GRANTED".equals(getStatusForPermission(statuses, "READ_MEDIA_IMAGES")) ||
                        "GRANTED".equals(getStatusForPermission(statuses, "READ_MEDIA_VIDEO"))
                )
        ) {
            storage_status = "GRANTED";
        } else if (
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
                "GRANTED".equals(getStatusForPermission(statuses, "READ_MEDIA_VISUAL_USER_SELECTED"))
        ) {
            storage_status = "LIMITED";
        } else if (
                "GRANTED".equals(getStatusForPermission(statuses, "READ_EXTERNAL_STORAGE"))
        ) {
            storage_status = "GRANTED";
        } else {
            storage_status = combinePermissionStatuses(statuses);
        }

        return combinePermissionStatuses(new String[]{ camera_status, storage_status });
    }

    public void markPermissionsRequested(String[] permissions) {
        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = prefs.edit();

        for (String permission : permissions) {
            editor.putBoolean(REQUESTED_PREFIX + permission, true);
        }

        editor.apply();
    }

    private String[] getStoragePermissions() {
        if (Build.VERSION.SDK_INT >= 34) {
            return new String[]{
                    Manifest.permission.READ_MEDIA_IMAGES,
                    Manifest.permission.READ_MEDIA_VIDEO,
                    Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED
            };
        } else if (Build.VERSION.SDK_INT >= 33) {
            return new String[]{
                    Manifest.permission.READ_MEDIA_IMAGES,
                    Manifest.permission.READ_MEDIA_VIDEO
            };
        } else {
            return new String[]{
                    Manifest.permission.READ_EXTERNAL_STORAGE,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE
            };
        }
    }

    private String permissionToCordovaName(String permission) {
        if (Manifest.permission.CAMERA.equals(permission)) {
            return "CAMERA";
        }
        if (Manifest.permission.READ_MEDIA_IMAGES.equals(permission)) {
            return "READ_MEDIA_IMAGES";
        }
        if (Manifest.permission.READ_MEDIA_VIDEO.equals(permission)) {
            return "READ_MEDIA_VIDEO";
        }
        if (Build.VERSION.SDK_INT >= 34 && Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED.equals(permission)) {
            return "READ_MEDIA_VISUAL_USER_SELECTED";
        }
        if (Manifest.permission.READ_EXTERNAL_STORAGE.equals(permission)) {
            return "READ_EXTERNAL_STORAGE";
        }
        if (Manifest.permission.WRITE_EXTERNAL_STORAGE.equals(permission)) {
            return "WRITE_EXTERNAL_STORAGE";
        }
        return permission;
    }

    private String getPermissionAuthorizationStatus(String permission, Activity activity) {
        if (ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED) {
            return "GRANTED";
        }

        if (!wasPermissionRequested(permission)) {
            return "NOT_REQUESTED";
        }

        if (activity != null && !ActivityCompat.shouldShowRequestPermissionRationale(activity, permission)) {
            return "DENIED_ALWAYS";
        }

        return "DENIED";
    }

    private boolean wasPermissionRequested(String permission) {
        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        return prefs.getBoolean(REQUESTED_PREFIX + permission, false);
    }

    private String getStatusForPermission(JSONObject statuses, String permission_name) {
        return statuses.has(permission_name) ? statuses.optString(permission_name, "DENIED") : "DENIED";
    }

    private boolean anyStatusIs(String status, String[] statuses) {
        for (String s : statuses) {
            if (status.equals(s)) {
                return true;
            }
        }
        return false;
    }

    private String combinePermissionStatuses(JSONObject permission_statuses) {
        String[] storage_permissions = getStoragePermissions();
        String[] statuses = new String[storage_permissions.length];

        for (int i = 0; i < storage_permissions.length; i++) {
            statuses[i] = getStatusForPermission(permission_statuses, permissionToCordovaName(storage_permissions[i]));
        }

        return combinePermissionStatuses(statuses);
    }

    private String combinePermissionStatuses(String[] statuses) {
        if (anyStatusIs("DENIED_ALWAYS", statuses)) {
            return "DENIED_ALWAYS";
        } else if (anyStatusIs("LIMITED", statuses)) {
            return "LIMITED";
        } else if (anyStatusIs("DENIED", statuses)) {
            return "DENIED";
        } else if (anyStatusIs("GRANTED", statuses)) {
            return "GRANTED";
        } else {
            return "NOT_REQUESTED";
        }
    }
}
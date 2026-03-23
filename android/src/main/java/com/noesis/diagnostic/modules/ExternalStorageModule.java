package com.noesis.diagnostic.modules;

import android.content.Context;
import android.os.Build;
import android.os.Environment;
import android.os.StatFs;

import androidx.core.os.EnvironmentCompat;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.PluginCall;

import java.io.File;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

public class ExternalStorageModule {

    private final Context context;

    public ExternalStorageModule(Context context) {
        this.context = context;
    }

    /*
     * Returns { details: [ { path, filePath, canWrite, freeSpace, type } ] }.
     * Only returns entries that are actually readable. Each entry includes
     * both the root mount path and the app-scoped Android path.
     *
     * "type" is "application" if the path contains "/Android" (scoped storage),
     * "root" otherwise (raw mount point).
     *
     * Matches Cordova's getExternalSdCardDetails() response shape exactly.
     */
    public void getExternalSdCardDetails(PluginCall call) {
        try {
            String[] storage_directories = get_storage_directories();

            JSArray details = new JSArray();

            for (String directory : storage_directories) {
                File file = new File(directory);
                if (!file.canRead()) {
                    continue;
                }

                JSObject detail = new JSObject();
                detail.put("path", directory);
                detail.put("filePath", "file://" + directory);
                detail.put("canWrite", file.canWrite());
                detail.put("freeSpace", get_free_space_in_bytes(directory));
                detail.put("type", directory.contains("Android") ? "application" : "root");

                details.put(detail);
            }

            JSObject result = new JSObject();
            result.put("details", details);
            call.resolve(result);
        } catch (Exception e) {
            call.reject("Failed to get external SD card details: " + e.getMessage(), e);
        }
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    private long get_free_space_in_bytes(String path) {
        try {
            StatFs stat = new StatFs(path);
            return stat.getAvailableBytes();
        } catch (IllegalArgumentException e) {
            return 0;
        }
    }

    /*
     * Discovers external storage directories using two strategies:
     *
     * Primary (API 19+): getExternalFilesDirs(null) returns all external storage paths
     * including secondary SD cards. We check if each is actually removable storage
     * (isExternalStorageRemovable on API 21+, or EnvironmentCompat.getStorageState below that).
     * Both the root and app-scoped paths are included.
     *
     * Fallback (pre-API 19 or if primary returns nothing): parse 'mount' for /dev/block/vold entries.
     * This is a best-effort shell approach — unreliable on newer Android but kept for old device parity.
     *
     * Post-processing on API 23+: filters results to only paths matching the SD card UUID format
     * (e.g., "1234-5678") since that's the only reliable removable storage signature.
     * On older API: filters by path names containing "ext" or "sdcard" as a heuristic.
     */
    private String[] get_storage_directories() {
        List<String> results = new ArrayList<>();

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            File[] external_dirs = context.getExternalFilesDirs(null);

            for (File file : external_dirs) {
                if (file == null) continue;

                String application_path = file.getPath();
                String root_path = application_path.split("/Android")[0];

                boolean add_path;
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    add_path = Environment.isExternalStorageRemovable(file);
                } else {
                    add_path = Environment.MEDIA_MOUNTED.equals(EnvironmentCompat.getStorageState(file));
                }

                if (add_path) {
                    results.add(root_path);
                    results.add(application_path);
                }
            }
        }

        if (results.isEmpty()) {
            String output = "";
            try {
                Process process = new ProcessBuilder()
                    .command("sh", "-c", "mount | grep /dev/block/vold")
                    .redirectErrorStream(true)
                    .start();

                process.waitFor();

                InputStream is = process.getInputStream();
                byte[] buffer = new byte[1024];
                int read;

                while ((read = is.read(buffer)) != -1) {
                    output += new String(buffer, 0, read);
                }

                is.close();
            } catch (Exception ignored) {
            }

            if (!output.trim().isEmpty()) {
                String[] device_points = output.split("\n");
                for (String vold_point : device_points) {
                    String[] parts = vold_point.split(" ");
                    if (parts.length > 2) {
                        results.add(parts[2]);
                    }
                }
            }
        }

        // Filter to removable storage only
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // API 23+: removable cards have a UUID-style path segment like "1A2B-3C4D"
            for (int i = 0; i < results.size(); i++) {
                if (!results.get(i).toLowerCase().matches(".*[0-9a-f]{4}[-][0-9a-f]{4}.*")) {
                    results.remove(i--);
                }
            }
        } else {
            // Below API 23: fall back to path name heuristic
            for (int i = 0; i < results.size(); i++) {
                String path = results.get(i).toLowerCase();
                if (!path.contains("ext") && !path.contains("sdcard")) {
                    results.remove(i--);
                }
            }
        }

        return results.toArray(new String[0]);
    }
}
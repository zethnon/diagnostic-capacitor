//JN - things to rememebr
//this is what defines a cpacitor android plugin that exposes 2 js methods and returns hardcoded responses for now
// js will call registerPlugin('DiagnosticPlugin') and if the name doesn't match, it will probs return "not implemented"

package com.noesis.diagnostic;

import android.Manifest;
import android.os.Build;

import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;

import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.annotation.Permission;
import com.getcapacitor.annotation.PermissionCallback;

import com.noesis.diagnostic.modules.LocationModule;

// in capacitor, permissions need to be deeclare. they are not ad-hoc, so we're only ehcking permissions with ContextCompact, this will work to give us  the status
// but for requesting permissions. i need to declare which permissions the plugins has for himself

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
        )
    }
)
public class DiagnosticPlugin extends Plugin {

    private LocationModule location;

    @Override
    public void load() {
        super.load();
        location = new LocationModule(this);
    }

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

        // on android 10 request background permission prompt for mode=always
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
}
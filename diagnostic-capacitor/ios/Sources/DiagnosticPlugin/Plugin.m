#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

CAP_PLUGIN(DiagnosticPlugin, "DiagnosticPlugin",
    CAP_PLUGIN_METHOD(getLocationAuthorizationStatus, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(requestLocationAuthorization, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(openLocationSettings, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(switchToLocationSettings, CAPPluginReturnPromise);

    CAP_PLUGIN_METHOD(isLocationEnabled, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(isLocationAvailable, CAPPluginReturnPromise);

    CAP_PLUGIN_METHOD(isGpsLocationEnabled, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(isNetworkLocationEnabled, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(isGpsLocationAvailable, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(isNetworkLocationAvailable, CAPPluginReturnPromise);

    CAP_PLUGIN_METHOD(getLocationMode, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(isCompassAvailable, CAPPluginReturnPromise);

    CAP_PLUGIN_METHOD(isLocationAuthorized, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getLocationAccuracyAuthorization, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(requestTemporaryFullAccuracyAuthorization, CAPPluginReturnPromise);
)
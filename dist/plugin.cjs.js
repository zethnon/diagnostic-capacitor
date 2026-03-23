'use strict';

var core = require('@capacitor/core');

const DiagnosticPlugin = core.registerPlugin('DiagnosticPlugin', {
    web: () => Promise.resolve().then(function () { return web; }).then(m => new m.DiagnosticPluginWeb()),
});

class DiagnosticPluginWeb extends core.WebPlugin {
    not_implemented_status() {
        return { status: 'not_implemented' };
    }
    async getLocationAuthorizationStatus() {
        return this.not_implemented_status();
    }
    async requestLocationAuthorization(_options) {
        return this.not_implemented_status();
    }
    async isLocationEnabled() {
        return { enabled: false };
    }
    async openLocationSettings() { }
    async isLocationAvailable() {
        return { available: false };
    }
    async getLocationMode() {
        return { mode: 'unknown' };
    }
    async isGpsLocationEnabled() {
        return { enabled: false };
    }
    async isNetworkLocationEnabled() {
        return { enabled: false };
    }
    async isGpsLocationAvailable() {
        return { available: false };
    }
    async isNetworkLocationAvailable() {
        return { available: false };
    }
    async switchToLocationSettings() { }
    async isCompassAvailable() {
        return { available: false };
    }
    async isLocationAuthorized() {
        return { value: false };
    }
    async getLocationAccuracyAuthorization() {
        return { value: 'full' };
    }
    async requestTemporaryFullAccuracyAuthorization(_options) {
        return { value: 'full' };
    }
    async switchToBluetoothSettings() { }
    async isBluetoothAvailable() {
        return { available: false };
    }
    async isBluetoothEnabled() {
        return { enabled: false };
    }
    async hasBluetoothSupport() {
        return { supported: false };
    }
    async hasBluetoothLESupport() {
        return { supported: false };
    }
    async hasBluetoothLEPeripheralSupport() {
        return { supported: false };
    }
    async setBluetoothState(_options) {
        throw new Error('not_implemented');
    }
    async getBluetoothState() {
        return { state: 'unknown' };
    }
    async getBluetoothAuthorizationStatuses() {
        return { statuses: {} };
    }
    async requestBluetoothAuthorization(_options) {
        return this.not_implemented_status();
    }
    async ensureBluetoothManager() { }
    async getBluetoothAuthorizationStatus() {
        return this.not_implemented_status();
    }
    async isCameraPresent() {
        return { present: false };
    }
    async requestCameraAuthorization(_options) {
        return this.not_implemented_status();
    }
    async getCameraAuthorizationStatus(_options) {
        return this.not_implemented_status();
    }
    async getCameraAuthorizationStatuses(_options) {
        return { statuses: {} };
    }
    async isRemoteNotificationsEnabled() {
        return { enabled: false };
    }
    async getRemoteNotificationTypes() {
        return { types: {} };
    }
    async isRegisteredForRemoteNotifications() {
        return { registered: false };
    }
    async getRemoteNotificationsAuthorizationStatus() {
        return this.not_implemented_status();
    }
    async requestRemoteNotificationsAuthorization(_options) {
        return this.not_implemented_status();
    }
    async switchToNotificationSettings() { }
    async switchToWifiSettings() { }
    async isWifiAvailable() {
        return { available: false };
    }
    async isWifiEnabled() {
        return { enabled: false };
    }
    async setWifiState(_options) {
        throw new Error('not_implemented');
    }
    async requestLocalNetworkAuthorization(_options) {
        return { value: 0 };
    }
    async getLocalNetworkAuthorizationStatus(_options) {
        return { value: 0 };
    }
    async isMicrophoneAuthorized() {
        throw this.unavailable('Microphone not available on web');
    }
    async getMicrophoneAuthorizationStatus() {
        throw this.unavailable('Microphone not available on web');
    }
    async requestMicrophoneAuthorization() {
        throw this.unavailable('Microphone not available on web');
    }
    async isMotionAvailable() {
        throw this.unavailable('Motion not available on web');
    }
    async isMotionRequestOutcomeAvailable() {
        throw this.unavailable('Motion not available on web');
    }
    async getMotionAuthorizationStatus() {
        throw this.unavailable('Motion not available on web');
    }
    async requestMotionAuthorization() {
        throw this.unavailable('Motion not available on web');
    }
    async getRemindersAuthorizationStatus() {
        throw this.unavailable('Reminders not available on web');
    }
    async isRemindersAuthorized() {
        throw this.unavailable('Reminders not available on web');
    }
    async requestRemindersAuthorization() {
        throw this.unavailable('Reminders not available on web');
    }
    async getExternalSdCardDetails() {
        return { details: [] };
    }
    async switchToNFCSettings() {
        throw this.unavailable('NFC settings are not available on web.');
    }
    async isNFCPresent() {
        return { present: false };
    }
    async isNFCEnabled() {
        return { enabled: false };
    }
    async isNFCAvailable() {
        return { available: false };
    }
    async getCalendarAuthorizationStatus() {
        return { value: 'not_determined' };
    }
    async isCalendarAuthorized() {
        return { value: false };
    }
    async requestCalendarAuthorization() {
        throw this.unavailable('Calendar authorization is not available on web.');
    }
    async getAddressBookAuthorizationStatus() {
        return { value: 'not_determined' };
    }
    async isAddressBookAuthorized() {
        return { value: false };
    }
    async requestAddressBookAuthorization() {
        throw this.unavailable('Contacts authorization is not available on web.');
    }
    async switchToSettings() {
        throw this.unimplemented('switchToSettings is not available on web.');
    }
    async enableDebug() {
        return;
    }
    async isADBModeEnabled() {
        throw this.unimplemented('isADBModeEnabled is not available on web.');
    }
    async isDataRoamingEnabled() {
        throw this.unimplemented('isDataRoamingEnabled is not available on web.');
    }
    async restart(_options) {
        throw this.unimplemented('restart is not available on web.');
    }
    async switchToMobileDataSettings() {
        throw this.unimplemented('switchToMobileDataSettings is not available on web.');
    }
    async switchToWirelessSettings() {
        throw this.unimplemented('switchToWirelessSettings is not available on web.');
    }
    async isBackgroundRefreshAuthorized() {
        throw this.unimplemented('isBackgroundRefreshAuthorized is not available on web.');
    }
}

var web = /*#__PURE__*/Object.freeze({
    __proto__: null,
    DiagnosticPluginWeb: DiagnosticPluginWeb
});

exports.DiagnosticPlugin = DiagnosticPlugin;
//# sourceMappingURL=plugin.cjs.js.map

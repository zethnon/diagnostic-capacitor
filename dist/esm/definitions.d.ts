import type { PluginListenerHandle } from '@capacitor/core';
export interface ExternalSdCardDetail {
    path: string;
    filePath: string;
    canWrite: boolean;
    freeSpace: number;
    type: 'root' | 'application';
}
export interface DiagnosticPlugin {
    enableDebug(): Promise<void>;
    getLocationAuthorizationStatus(): Promise<{
        status: string;
    }>;
    requestLocationAuthorization(options?: {
        mode?: 'always' | 'when_in_use';
    }): Promise<{
        status: string;
    }>;
    isLocationEnabled(): Promise<{
        enabled: boolean;
    }>;
    openLocationSettings(): Promise<void>;
    isLocationAvailable(): Promise<{
        available: boolean;
    }>;
    getLocationMode(): Promise<{
        mode: string;
    }>;
    isGpsLocationEnabled(): Promise<{
        enabled: boolean;
    }>;
    isNetworkLocationEnabled(): Promise<{
        enabled: boolean;
    }>;
    isGpsLocationAvailable(): Promise<{
        available: boolean;
    }>;
    isNetworkLocationAvailable(): Promise<{
        available: boolean;
    }>;
    switchToLocationSettings(): Promise<void>;
    isCompassAvailable(): Promise<{
        available: boolean;
    }>;
    isLocationAuthorized(): Promise<{
        value: boolean;
    }>;
    getLocationAccuracyAuthorization(): Promise<{
        value: 'full' | 'reduced';
    }>;
    requestTemporaryFullAccuracyAuthorization(options: {
        purpose: string;
    }): Promise<{
        value: 'full' | 'reduced';
    }>;
    switchToBluetoothSettings(): Promise<void>;
    isBluetoothAvailable(): Promise<{
        available: boolean;
    }>;
    isBluetoothEnabled(): Promise<{
        enabled: boolean;
    }>;
    hasBluetoothSupport(): Promise<{
        supported: boolean;
    }>;
    hasBluetoothLESupport(): Promise<{
        supported: boolean;
    }>;
    hasBluetoothLEPeripheralSupport(): Promise<{
        supported: boolean;
    }>;
    setBluetoothState(options: {
        enable: boolean;
    }): Promise<void>;
    getBluetoothState(): Promise<{
        state: string;
    }>;
    getBluetoothAuthorizationStatuses(): Promise<{
        statuses: Record<string, string>;
    }>;
    requestBluetoothAuthorization(options?: {
        permissions?: Array<'BLUETOOTH_ADVERTISE' | 'BLUETOOTH_CONNECT' | 'BLUETOOTH_SCAN'>;
    }): Promise<{
        status: string;
    }>;
    ensureBluetoothManager(): Promise<void>;
    getBluetoothAuthorizationStatus(): Promise<{
        status: string;
    }>;
    addListener(eventName: 'bluetoothStateChange', listenerFunc: (event: {
        state: string;
    }) => void): Promise<PluginListenerHandle>;
    removeAllListeners(): Promise<void>;
    isCameraPresent(): Promise<{
        present: boolean;
    }>;
    requestCameraAuthorization(options?: {
        storage?: boolean;
    }): Promise<{
        status: string;
    }>;
    getCameraAuthorizationStatus(options?: {
        storage?: boolean;
    }): Promise<{
        status: string;
    }>;
    getCameraAuthorizationStatuses(options?: {
        storage?: boolean;
    }): Promise<{
        statuses: Record<string, string>;
    }>;
    isRemoteNotificationsEnabled(): Promise<{
        enabled: boolean;
    }>;
    getRemoteNotificationTypes(): Promise<{
        types: Record<string, '0' | '1'>;
    }>;
    isRegisteredForRemoteNotifications(): Promise<{
        registered: boolean;
    }>;
    getRemoteNotificationsAuthorizationStatus(): Promise<{
        status: string;
    }>;
    requestRemoteNotificationsAuthorization(options?: {
        types?: Array<'alert' | 'sound' | 'badge'>;
        omitRegistration?: boolean;
    }): Promise<{
        status: string;
    }>;
    switchToNotificationSettings(): Promise<void>;
    switchToWifiSettings(): Promise<void>;
    isWifiAvailable(): Promise<{
        available: boolean;
    }>;
    isWifiEnabled(): Promise<{
        enabled: boolean;
    }>;
    setWifiState(options: {
        enable: boolean;
    }): Promise<void>;
    requestLocalNetworkAuthorization(options?: {
        timeoutMs?: number;
    }): Promise<{
        value: number;
    }>;
    getLocalNetworkAuthorizationStatus(options?: {
        timeoutMs?: number;
    }): Promise<{
        value: number;
    }>;
    getExternalSdCardDetails(): Promise<{
        details: ExternalSdCardDetail[];
    }>;
    isMicrophoneAuthorized(): Promise<{
        value: boolean;
    }>;
    getMicrophoneAuthorizationStatus(): Promise<{
        value: string;
    }>;
    requestMicrophoneAuthorization(): Promise<{
        value: boolean;
    }>;
    isMotionAvailable(): Promise<{
        value: boolean;
    }>;
    isMotionRequestOutcomeAvailable(): Promise<{
        value: boolean;
    }>;
    getMotionAuthorizationStatus(): Promise<{
        value: string;
    }>;
    requestMotionAuthorization(): Promise<{
        value: string;
    }>;
    getRemindersAuthorizationStatus(): Promise<{
        value: string;
    }>;
    isRemindersAuthorized(): Promise<{
        value: boolean;
    }>;
    requestRemindersAuthorization(): Promise<{
        value: boolean;
    }>;
    switchToNFCSettings(): Promise<void>;
    isNFCPresent(): Promise<{
        present: boolean;
    }>;
    isNFCEnabled(): Promise<{
        enabled: boolean;
    }>;
    isNFCAvailable(): Promise<{
        available: boolean;
    }>;
    addListener(eventName: 'nfcStateChange', listenerFunc: (event: {
        state: string;
    }) => void): Promise<PluginListenerHandle>;
    getCalendarAuthorizationStatus(): Promise<{
        value: string;
    }>;
    isCalendarAuthorized(): Promise<{
        value: boolean;
    }>;
    requestCalendarAuthorization(): Promise<{
        value: boolean;
    }>;
    getAddressBookAuthorizationStatus(): Promise<{
        value: string;
    }>;
    isAddressBookAuthorized(): Promise<{
        value: boolean;
    }>;
    requestAddressBookAuthorization(): Promise<{
        value: boolean;
    }>;
    /**
     * Opens the app's own page in the device Settings app.
     * Cross-platform.
     */
    switchToSettings(): Promise<void>;
    /**
     * Enables verbose native logging.
     * No-op on Capacitor — use Logcat (Android) or Xcode console (iOS) instead.
     */
    enableDebug(): Promise<void>;
    /**
     * Returns whether ADB / USB debugging mode is enabled on the device.
     * Android only — always returns false on iOS.
     */
    isADBModeEnabled(): Promise<{
        enabled: boolean;
    }>;
    /**
     * Returns whether data roaming is enabled.
     * Android only (API 32 and below) — returns false on iOS and Android 13+.
     */
    isDataRoamingEnabled(): Promise<{
        enabled: boolean;
    }>;
    /**
     * Restarts the application.
     * Android only — rejects on iOS (not possible via public API).
     * @param cold - if true, cold restarts (kills the process); if false, warm restarts (recreates Activity only).
     */
    restart(options: {
        cold: boolean;
    }): Promise<void>;
    /**
     * Opens the mobile data / roaming settings screen.
     * Android: ACTION_DATA_ROAMING_SETTINGS.
     * iOS: falls back to general app Settings.
     */
    switchToMobileDataSettings(): Promise<void>;
    /**
     * Opens the wireless settings screen (WiFi, Bluetooth, mobile networks).
     * Android: ACTION_WIRELESS_SETTINGS.
     * iOS: falls back to general app Settings.
     */
    switchToWirelessSettings(): Promise<void>;
    /**
     * Returns the background app refresh authorization status.
     * iOS only — returns "not_determined" on Android.
     * Possible values: "authorized", "denied_always", "restricted", "not_determined".
     */
    isBackgroundRefreshAuthorized(): Promise<{
        value: string;
    }>;
    /**
     * Registers a listener for location state changes.
     * Fires when the user toggles location services or changes app location permission.
     * Payload: { state: string } — matches getLocationMode() strings on Android,
     * auth status strings on iOS.
     */
    addListener(eventName: 'locationStateChange', listenerFunc: (data: {
        state: string;
    }) => void): Promise<PluginListenerHandle>;
}

import { WebPlugin } from '@capacitor/core';
import type { DiagnosticPlugin, ExternalSdCardDetail } from './definitions';
export declare class DiagnosticPluginWeb extends WebPlugin implements DiagnosticPlugin {
    private not_implemented_status;
    getLocationAuthorizationStatus(): Promise<{
        status: string;
    }>;
    requestLocationAuthorization(_options?: {
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
    requestTemporaryFullAccuracyAuthorization(_options: {
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
    setBluetoothState(_options: {
        enable: boolean;
    }): Promise<void>;
    getBluetoothState(): Promise<{
        state: string;
    }>;
    getBluetoothAuthorizationStatuses(): Promise<{
        statuses: Record<string, string>;
    }>;
    requestBluetoothAuthorization(_options?: {
        permissions?: Array<'BLUETOOTH_ADVERTISE' | 'BLUETOOTH_CONNECT' | 'BLUETOOTH_SCAN'>;
    }): Promise<{
        status: string;
    }>;
    ensureBluetoothManager(): Promise<void>;
    getBluetoothAuthorizationStatus(): Promise<{
        status: string;
    }>;
    isCameraPresent(): Promise<{
        present: boolean;
    }>;
    requestCameraAuthorization(_options?: {
        storage?: boolean;
    }): Promise<{
        status: string;
    }>;
    getCameraAuthorizationStatus(_options?: {
        storage?: boolean;
    }): Promise<{
        status: string;
    }>;
    getCameraAuthorizationStatuses(_options?: {
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
    requestRemoteNotificationsAuthorization(_options?: {
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
    setWifiState(_options: {
        enable: boolean;
    }): Promise<void>;
    requestLocalNetworkAuthorization(_options?: {
        timeoutMs?: number;
    }): Promise<{
        value: number;
    }>;
    getLocalNetworkAuthorizationStatus(_options?: {
        timeoutMs?: number;
    }): Promise<{
        value: number;
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
    getExternalSdCardDetails(): Promise<{
        details: ExternalSdCardDetail[];
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
    switchToSettings(): Promise<void>;
    enableDebug(): Promise<void>;
    isADBModeEnabled(): Promise<{
        enabled: boolean;
    }>;
    isDataRoamingEnabled(): Promise<{
        enabled: boolean;
    }>;
    restart(_options: {
        cold: boolean;
    }): Promise<void>;
    switchToMobileDataSettings(): Promise<void>;
    switchToWirelessSettings(): Promise<void>;
    isBackgroundRefreshAuthorized(): Promise<{
        value: string;
    }>;
}

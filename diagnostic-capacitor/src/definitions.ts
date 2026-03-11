import type { PluginListenerHandle } from '@capacitor/core';

export interface DiagnosticPlugin {
  // -----------------------
  // Location
  // -----------------------

  /**
   * Returns the current location authorization status (Cordova parity strings).
   */
  getLocationAuthorizationStatus(): Promise<{ status: string }>;

  /**
   * Requests location authorization.
   * `mode` maps to Cordova semantics: 'always' | 'when_in_use'
   */
  requestLocationAuthorization(options?: {
    mode?: 'always' | 'when_in_use';
  }): Promise<{ status: string }>;

  /**
   * True if location services are enabled at OS level.
   */
  isLocationEnabled(): Promise<{ enabled: boolean }>;

  /**
   * Opens the OS-level Location settings screen (best-effort per platform).
   */
  openLocationSettings(): Promise<void>;

  /**
   * True if location is available for use (authorization + services enabled, per Cordova behavior).
   */
  isLocationAvailable(): Promise<{ available: boolean }>;

  /**
   * Returns the current location mode (platform-specific string, Cordova parity).
   */
  getLocationMode(): Promise<{ mode: string }>;

  /**
   * True if GPS provider is enabled (Android-specific; iOS returns best-effort parity).
   */
  isGpsLocationEnabled(): Promise<{ enabled: boolean }>;

  /**
   * True if Network provider is enabled (Android-specific; iOS returns best-effort parity).
   */
  isNetworkLocationEnabled(): Promise<{ enabled: boolean }>;

  /**
   * True if GPS location is available (Android-specific; iOS returns best-effort parity).
   */
  isGpsLocationAvailable(): Promise<{ available: boolean }>;

  /**
   * True if Network location is available (Android-specific; iOS returns best-effort parity).
   */
  isNetworkLocationAvailable(): Promise<{ available: boolean }>;

  /**
   * Opens the OS-level Location settings screen (Cordova-style method naming).
   */
  switchToLocationSettings(): Promise<void>;

  /**
   * True if device has a compass / magnetometer available.
   */
  isCompassAvailable(): Promise<{ available: boolean }>;

  /**
   * True if app is authorized to use location services (authorization only).
   */
  isLocationAuthorized(): Promise<{ value: boolean }>;

  /**
   * iOS-only accuracy authorization.
   * Returns "full" or "reduced" (iOS 14+); other platforms default to "full".
   */
  getLocationAccuracyAuthorization(): Promise<{ value: 'full' | 'reduced' }>;

  /**
   * iOS-only temporary full accuracy request (iOS 14+).
   * `purpose` must match a key in Info.plist (NSLocationTemporaryUsageDescriptionDictionary).
   */
  requestTemporaryFullAccuracyAuthorization(options: {
    purpose: string;
  }): Promise<{ value: 'full' | 'reduced' }>;

  // -----------------------
  // Bluetooth
  // -----------------------

  /**
   * Opens OS Bluetooth settings screen.
   */
  switchToBluetoothSettings(): Promise<void>;

  /**
   * True if device supports Bluetooth and Bluetooth is enabled.
   */
  isBluetoothAvailable(): Promise<{ available: boolean }>;

  /**
   * True if Bluetooth adapter exists and is enabled.
   */
  isBluetoothEnabled(): Promise<{ enabled: boolean }>;

  /**
   * True if device has FEATURE_BLUETOOTH.
   */
  hasBluetoothSupport(): Promise<{ supported: boolean }>;

  /**
   * True if device has FEATURE_BLUETOOTH_LE.
   */
  hasBluetoothLESupport(): Promise<{ supported: boolean }>;

  /**
   * True if adapter supports multiple advertisement (peripheral mode).
   */
  hasBluetoothLEPeripheralSupport(): Promise<{ supported: boolean }>;

  /**
   * Attempts to enable/disable Bluetooth.
   * Android 13+ rejects (matches Cordova behavior).
   */
  setBluetoothState(options: { enable: boolean }): Promise<void>;

  /**
   * Returns Bluetooth hardware state string (Cordova parity):
   * Android: unknown|powered_on|powered_off|powering_on|powering_off
   * iOS: powered_on|powered_off|unauthorized|unsupported|resetting|unknown
   */
  getBluetoothState(): Promise<{ state: string }>;

  /**
   * Android: returns per-permission status map for BLUETOOTH_* runtime permissions (SDK>=31).
   * iOS: returns a single `authorization` string.
   */
  getBluetoothAuthorizationStatuses(): Promise<{
    statuses: Record<string, string>;
  }>;

  /**
   * Android: request BLUETOOTH_* permissions (optionally specify which).
   * iOS: triggers permission prompt if not determined.
   */
  requestBluetoothAuthorization(options?: {
    permissions?: Array<'BLUETOOTH_ADVERTISE' | 'BLUETOOTH_CONNECT' | 'BLUETOOTH_SCAN'>;
  }): Promise<{ status: string }>;

  /**
   * iOS-only explicit init of Bluetooth manager (parity with Cordova).
   * Android is a no-op.
   */
  ensureBluetoothManager(): Promise<void>;

  /**
   * iOS-only single authorization status string (granted|denied|not_determined).
   * Android returns derived status (granted if all requested perms granted, otherwise denied/denied_always).
   */
  getBluetoothAuthorizationStatus(): Promise<{ status: string }>;

  /**
   * Bluetooth state change event. Fired when underlying OS BT state changes.
   */
  addListener(
    eventName: 'bluetoothStateChange',
    listenerFunc: (event: { state: string }) => void
  ): Promise<PluginListenerHandle>;

  removeAllListeners(): Promise<void>;

  // -----------------------
  // Camera
  // -----------------------

  /**
   * True if device has a camera.
   */
  isCameraPresent(): Promise<{ present: boolean }>;

  /**
   * Requests camera authorization.
   * If `storage` is true, also requests storage/media library permissions needed by Cordova parity.
   */
  requestCameraAuthorization(options?: {
    storage?: boolean;
  }): Promise<{ status: string }>;

  /**
   * Returns combined camera authorization status.
   * If `storage` is true, combines camera + storage/media permissions using Cordova parity.
   */
  getCameraAuthorizationStatus(options?: {
    storage?: boolean;
  }): Promise<{ status: string }>;

  /**
   * Returns raw camera/media permission statuses map.
   */
  getCameraAuthorizationStatuses(options?: {
    storage?: boolean;
  }): Promise<{
    statuses: Record<string, string>;
  }>;

  // -----------------------
  // Notifications
  // -----------------------

  /**
   * True if remote/push notifications are effectively enabled for the app.
   */
  isRemoteNotificationsEnabled(): Promise<{ enabled: boolean }>;

  /**
   * Returns Cordova-style notification types map.
   * iOS returns actual alert/sound/badge values.
   * Android returns best-effort parity using app-level notification enablement.
   */
  getRemoteNotificationTypes(): Promise<{
    types: Record<string, '0' | '1'>;
  }>;

  /**
   * iOS exposes APNS registration state directly.
   * Android returns best-effort parity.
   */
  isRegisteredForRemoteNotifications(): Promise<{ registered: boolean }>;

  /**
   * Returns notification authorization status.
   */
  getRemoteNotificationsAuthorizationStatus(): Promise<{ status: string }>;

  /**
   * Requests remote notification authorization.
   */
  requestRemoteNotificationsAuthorization(options?: {
    types?: Array<'alert' | 'sound' | 'badge'>;
    omitRegistration?: boolean;
  }): Promise<{ status: string }>;

  /**
   * Opens the app notification settings screen.
   */
  switchToNotificationSettings(): Promise<void>;
}
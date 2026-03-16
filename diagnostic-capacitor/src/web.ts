import { WebPlugin } from '@capacitor/core';
import type { DiagnosticPlugin } from './definitions';

export class DiagnosticPluginWeb extends WebPlugin implements DiagnosticPlugin {
  // -----------------------
  // helpers
  // -----------------------

  private not_implemented_status(): { status: string } {
    return { status: 'not_implemented' };
  }

  // -----------------------
  // Location
  // -----------------------

  async getLocationAuthorizationStatus(): Promise<{ status: string }> {
    return this.not_implemented_status();
  }

  async requestLocationAuthorization(_options?: {
    mode?: 'always' | 'when_in_use';
  }): Promise<{ status: string }> {
    return this.not_implemented_status();
  }

  async isLocationEnabled(): Promise<{ enabled: boolean }> {
    return { enabled: false };
  }

  async openLocationSettings(): Promise<void> {}

  async isLocationAvailable(): Promise<{ available: boolean }> {
    return { available: false };
  }

  async getLocationMode(): Promise<{ mode: string }> {
    return { mode: 'unknown' };
  }

  async isGpsLocationEnabled(): Promise<{ enabled: boolean }> {
    return { enabled: false };
  }

  async isNetworkLocationEnabled(): Promise<{ enabled: boolean }> {
    return { enabled: false };
  }

  async isGpsLocationAvailable(): Promise<{ available: boolean }> {
    return { available: false };
  }

  async isNetworkLocationAvailable(): Promise<{ available: boolean }> {
    return { available: false };
  }

  async switchToLocationSettings(): Promise<void> {}

  async isCompassAvailable(): Promise<{ available: boolean }> {
    return { available: false };
  }

  async isLocationAuthorized(): Promise<{ value: boolean }> {
    return { value: false };
  }

  async getLocationAccuracyAuthorization(): Promise<{ value: 'full' | 'reduced' }> {
    return { value: 'full' };
  }

  async requestTemporaryFullAccuracyAuthorization(_options: {
    purpose: string;
  }): Promise<{ value: 'full' | 'reduced' }> {
    return { value: 'full' };
  }

  // -----------------------
  // Bluetooth
  // -----------------------

  async switchToBluetoothSettings(): Promise<void> {}

  async isBluetoothAvailable(): Promise<{ available: boolean }> {
    return { available: false };
  }

  async isBluetoothEnabled(): Promise<{ enabled: boolean }> {
    return { enabled: false };
  }

  async hasBluetoothSupport(): Promise<{ supported: boolean }> {
    return { supported: false };
  }

  async hasBluetoothLESupport(): Promise<{ supported: boolean }> {
    return { supported: false };
  }

  async hasBluetoothLEPeripheralSupport(): Promise<{ supported: boolean }> {
    return { supported: false };
  }

  async setBluetoothState(_options: { enable: boolean }): Promise<void> {
    throw new Error('not_implemented');
  }

  async getBluetoothState(): Promise<{ state: string }> {
    return { state: 'unknown' };
  }

  async getBluetoothAuthorizationStatuses(): Promise<{ statuses: Record<string, string> }> {
    return { statuses: {} };
  }

  async requestBluetoothAuthorization(_options?: {
    permissions?: Array<'BLUETOOTH_ADVERTISE' | 'BLUETOOTH_CONNECT' | 'BLUETOOTH_SCAN'>;
  }): Promise<{ status: string }> {
    return this.not_implemented_status();
  }

  async ensureBluetoothManager(): Promise<void> {}

  async getBluetoothAuthorizationStatus(): Promise<{ status: string }> {
    return this.not_implemented_status();
  }

  // -----------------------
  // Camera
  // -----------------------

  async isCameraPresent(): Promise<{ present: boolean }> {
    return { present: false };
  }

  async requestCameraAuthorization(_options?: {
    storage?: boolean;
  }): Promise<{ status: string }> {
    return this.not_implemented_status();
  }

  async getCameraAuthorizationStatus(_options?: {
    storage?: boolean;
  }): Promise<{ status: string }> {
    return this.not_implemented_status();
  }

  async getCameraAuthorizationStatuses(_options?: {
    storage?: boolean;
  }): Promise<{ statuses: Record<string, string> }> {
    return { statuses: {} };
  }

  // -----------------------
  // Notifications
  // -----------------------

  async isRemoteNotificationsEnabled(): Promise<{ enabled: boolean }> {
    return { enabled: false };
  }

  async getRemoteNotificationTypes(): Promise<{ types: Record<string, '0' | '1'> }> {
    return { types: {} };
  }

  async isRegisteredForRemoteNotifications(): Promise<{ registered: boolean }> {
    return { registered: false };
  }

  async getRemoteNotificationsAuthorizationStatus(): Promise<{ status: string }> {
    return this.not_implemented_status();
  }

  async requestRemoteNotificationsAuthorization(_options?: {
    types?: Array<'alert' | 'sound' | 'badge'>;
    omitRegistration?: boolean;
  }): Promise<{ status: string }> {
    return this.not_implemented_status();
  }

  async switchToNotificationSettings(): Promise<void> {}

  // -----------------------
  // Wifi
  // -----------------------

  async switchToWifiSettings(): Promise<void> {}

  async isWifiAvailable(): Promise<{ available: boolean }> {
    return { available: false };
  }

  async isWifiEnabled(): Promise<{ enabled: boolean }> {
    return { enabled: false };
  }

  async setWifiState(_options: { enable: boolean }): Promise<void> {
    throw new Error('not_implemented');
  }

  async requestLocalNetworkAuthorization(_options?: {
    timeoutMs?: number;
  }): Promise<{ value: number }> {
    return { value: 0 };
  }

  async getLocalNetworkAuthorizationStatus(_options?: {
    timeoutMs?: number;
  }): Promise<{ value: number }> {
    return { value: 0 };
  }
}
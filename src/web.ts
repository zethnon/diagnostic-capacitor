import { WebPlugin } from '@capacitor/core';
import type { DiagnosticPlugin } from './definitions';

export class DiagnosticPluginWeb extends WebPlugin implements DiagnosticPlugin {
  async getLocationAuthorizationStatus(): Promise<{ status: string }> {
    return { status: 'not_implemented' };
  }

  async requestLocationAuthorization(_options?: {
    mode?: 'always' | 'when_in_use';
  }): Promise<{ status: string }> {
    return { status: 'not_implemented' };
  }

  async isLocationEnabled(): Promise<{ enabled: boolean }> {
    return { enabled: false };
  }

  async openLocationSettings(): Promise<void> {
    // no-op on web
  }

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

  async switchToLocationSettings(): Promise<void> {
    // no-op on web
  }

  async isCompassAvailable(): Promise<{ available: boolean }> {
    return { available: false };
  }
}
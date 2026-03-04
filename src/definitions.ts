export interface DiagnosticPluginPlugin {
  getLocationAuthorizationStatus(): Promise<{
    status: string;
  }>;

  requestLocationAuthorization(options?: {
    mode?: 'always' | 'when_in_use';
  }): Promise<{
    status: string;
  }>;

  isLocationEnabled(): Promise<{ enabled: boolean }>;

  openLocationSettings(): Promise<void>;

  isLocationAvailable(): Promise<{ available: boolean }>;

  getLocationMode(): Promise<{ mode: string }>;

  isGpsLocationEnabled(): Promise<{ enabled: boolean }>;

  isNetworkLocationEnabled(): Promise<{ enabled: boolean }>;

  isGpsLocationAvailable(): Promise<{ available: boolean }>;

  isNetworkLocationAvailable(): Promise<{ available: boolean }>;

  switchToLocationSettings(): Promise<void>;

  isCompassAvailable(): Promise<{ available: boolean }>;
}
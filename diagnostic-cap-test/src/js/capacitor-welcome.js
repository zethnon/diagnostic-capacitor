import { SplashScreen } from '@capacitor/splash-screen';
import { Camera } from '@capacitor/camera';
import { registerPlugin } from '@capacitor/core';

const DiagnosticPlugin = registerPlugin('DiagnosticPlugin');

// =============================================================
// LOGGING HELPERS
// All logs use [DIAG] prefix for easy filtering in Xcode console
// Filter by: [DIAG] to see only test output
// =============================================================

function log(module, method, result) {
  console.log(`[DIAG][${module}] ${method} =>`, JSON.stringify(result));
}

function logStart(module) {
  console.log(`[DIAG][${module}] ========== START ==========`);
}

function logDone(module) {
  console.log(`[DIAG][${module}] ========== DONE ==========`);
}

function logInfo(message) {
  console.log(`[DIAG][INFO] ${message}`);
}

function logError(module, method, error) {
  console.error(`[DIAG][${module}][ERROR] ${method} =>`, error && error.message ? error.message : JSON.stringify(error));
}

async function safeCall(module, method, fn) {
  try {
    const res = await fn();
    log(module, method, res);
    return res;
  } catch (e) {
    logError(module, method, e);
    return null;
  }
}

// =============================================================
// SMOKE MARKER — visible top-left corner of the app UI
// =============================================================

function setMarker(text) {
  let el = document.getElementById('diag-smoke');
  if (!el) {
    el = document.createElement('div');
    el.id = 'diag-smoke';
    el.style.cssText =
      'position:fixed;top:0;left:0;right:0;z-index:99999;padding:6px 10px;background:#111;color:#0f0;font-family:monospace;font-size:12px;word-break:break-all;';
    document.body.appendChild(el);
  }
  el.textContent = text;
  document.title = text;
}

// =============================================================
// TEST SUITES
// =============================================================

async function testLocation() {
  logStart('Location');
  await safeCall('Location', 'getLocationAuthorizationStatus', () => DiagnosticPlugin.getLocationAuthorizationStatus());
  await safeCall('Location', 'isLocationEnabled', () => DiagnosticPlugin.isLocationEnabled());
  await safeCall('Location', 'isLocationAvailable', () => DiagnosticPlugin.isLocationAvailable());
  await safeCall('Location', 'isLocationAuthorized', () => DiagnosticPlugin.isLocationAuthorized());
  await safeCall('Location', 'getLocationMode', () => DiagnosticPlugin.getLocationMode());
  await safeCall('Location', 'getLocationAccuracyAuthorization', () => DiagnosticPlugin.getLocationAccuracyAuthorization());
  await safeCall('Location', 'isGpsLocationEnabled', () => DiagnosticPlugin.isGpsLocationEnabled());
  await safeCall('Location', 'isNetworkLocationEnabled', () => DiagnosticPlugin.isNetworkLocationEnabled());
  await safeCall('Location', 'isGpsLocationAvailable', () => DiagnosticPlugin.isGpsLocationAvailable());
  await safeCall('Location', 'isNetworkLocationAvailable', () => DiagnosticPlugin.isNetworkLocationAvailable());
  await safeCall('Location', 'isCompassAvailable', () => DiagnosticPlugin.isCompassAvailable());
  // Triggers permission dialog — runs last
  await safeCall('Location', 'requestLocationAuthorization(when_in_use)', () => DiagnosticPlugin.requestLocationAuthorization({ mode: 'when_in_use' }));
  logDone('Location');
}

async function testBluetooth() {
  logStart('Bluetooth');

  let bluetoothListener = null;
  try {
    bluetoothListener = await DiagnosticPlugin.addListener('bluetoothStateChange', event => {
      log('Bluetooth', 'EVENT:bluetoothStateChange', event);
    });
  } catch (e) {
    logError('Bluetooth', 'addListener(bluetoothStateChange)', e);
  }

  await safeCall('Bluetooth', 'ensureBluetoothManager', () => DiagnosticPlugin.ensureBluetoothManager());
  await safeCall('Bluetooth', 'getBluetoothState', () => DiagnosticPlugin.getBluetoothState());
  await safeCall('Bluetooth', 'isBluetoothAvailable', () => DiagnosticPlugin.isBluetoothAvailable());
  await safeCall('Bluetooth', 'isBluetoothEnabled', () => DiagnosticPlugin.isBluetoothEnabled());
  await safeCall('Bluetooth', 'hasBluetoothSupport', () => DiagnosticPlugin.hasBluetoothSupport());
  await safeCall('Bluetooth', 'hasBluetoothLESupport', () => DiagnosticPlugin.hasBluetoothLESupport());
  await safeCall('Bluetooth', 'hasBluetoothLEPeripheralSupport', () => DiagnosticPlugin.hasBluetoothLEPeripheralSupport());
  await safeCall('Bluetooth', 'getBluetoothAuthorizationStatus', () => DiagnosticPlugin.getBluetoothAuthorizationStatus());
  await safeCall('Bluetooth', 'getBluetoothAuthorizationStatuses', () => DiagnosticPlugin.getBluetoothAuthorizationStatuses());
  // Triggers permission dialog — runs last
  await safeCall('Bluetooth', 'requestBluetoothAuthorization', () => DiagnosticPlugin.requestBluetoothAuthorization());

  if (bluetoothListener) {
    try { await bluetoothListener.remove(); } catch (e) { logError('Bluetooth', 'removeListener', e); }
  }

  logDone('Bluetooth');
}

async function testCamera() {
  logStart('Camera');
  await safeCall('Camera', 'isCameraPresent', () => DiagnosticPlugin.isCameraPresent());
  await safeCall('Camera', 'getCameraAuthorizationStatus(camera-only)', () => DiagnosticPlugin.getCameraAuthorizationStatus({ storage: false }));
  await safeCall('Camera', 'getCameraAuthorizationStatus(with-storage)', () => DiagnosticPlugin.getCameraAuthorizationStatus({ storage: true }));
  await safeCall('Camera', 'getCameraAuthorizationStatuses(camera-only)', () => DiagnosticPlugin.getCameraAuthorizationStatuses({ storage: false }));
  await safeCall('Camera', 'getCameraAuthorizationStatuses(with-storage)', () => DiagnosticPlugin.getCameraAuthorizationStatuses({ storage: true }));
  // Triggers permission dialog — runs last
  await safeCall('Camera', 'requestCameraAuthorization(camera-only)', () => DiagnosticPlugin.requestCameraAuthorization({ storage: false }));
  await safeCall('Camera', 'requestCameraAuthorization(with-storage)', () => DiagnosticPlugin.requestCameraAuthorization({ storage: true }));
  logDone('Camera');
}

async function testNotifications() {
  logStart('Notifications');
  await safeCall('Notifications', 'getRemoteNotificationsAuthorizationStatus', () => DiagnosticPlugin.getRemoteNotificationsAuthorizationStatus());
  await safeCall('Notifications', 'isRemoteNotificationsEnabled', () => DiagnosticPlugin.isRemoteNotificationsEnabled());
  await safeCall('Notifications', 'isRegisteredForRemoteNotifications', () => DiagnosticPlugin.isRegisteredForRemoteNotifications());
  await safeCall('Notifications', 'getRemoteNotificationTypes', () => DiagnosticPlugin.getRemoteNotificationTypes());
  // Triggers permission dialog — runs last
  await safeCall('Notifications', 'requestRemoteNotificationsAuthorization', () =>
    DiagnosticPlugin.requestRemoteNotificationsAuthorization({ types: ['alert', 'sound', 'badge'], omitRegistration: false })
  );
  logDone('Notifications');
}

async function testWifi() {
  logStart('Wifi');
  await safeCall('Wifi', 'isWifiAvailable', () => DiagnosticPlugin.isWifiAvailable());
  await safeCall('Wifi', 'isWifiEnabled', () => DiagnosticPlugin.isWifiEnabled());
  await safeCall('Wifi', 'getLocalNetworkAuthorizationStatus', () => DiagnosticPlugin.getLocalNetworkAuthorizationStatus({ timeoutMs: 3000 }));
  // Triggers permission dialog — runs last
  await safeCall('Wifi', 'requestLocalNetworkAuthorization', () => DiagnosticPlugin.requestLocalNetworkAuthorization({ timeoutMs: 5000 }));
  logDone('Wifi');
}

async function testMicrophone() {
  logStart('Microphone');
  await safeCall('Microphone', 'getMicrophoneAuthorizationStatus', () => DiagnosticPlugin.getMicrophoneAuthorizationStatus());
  await safeCall('Microphone', 'isMicrophoneAuthorized', () => DiagnosticPlugin.isMicrophoneAuthorized());
  // Triggers permission dialog — runs last
  await safeCall('Microphone', 'requestMicrophoneAuthorization', () => DiagnosticPlugin.requestMicrophoneAuthorization());
  logDone('Microphone');
}

async function testMotion() {
  logStart('Motion');
  await safeCall('Motion', 'isMotionAvailable', () => DiagnosticPlugin.isMotionAvailable());
  await safeCall('Motion', 'isMotionRequestOutcomeAvailable', () => DiagnosticPlugin.isMotionRequestOutcomeAvailable());
  await safeCall('Motion', 'getMotionAuthorizationStatus', () => DiagnosticPlugin.getMotionAuthorizationStatus());
  // Triggers permission dialog — runs last
  await safeCall('Motion', 'requestMotionAuthorization', () => DiagnosticPlugin.requestMotionAuthorization());
  logDone('Motion');
}

async function testReminders() {
  logStart('Reminders');
  await safeCall('Reminders', 'getRemindersAuthorizationStatus', () => DiagnosticPlugin.getRemindersAuthorizationStatus());
  await safeCall('Reminders', 'isRemindersAuthorized', () => DiagnosticPlugin.isRemindersAuthorized());
  // Triggers permission dialog — runs last
  await safeCall('Reminders', 'requestRemindersAuthorization', () => DiagnosticPlugin.requestRemindersAuthorization());
  logDone('Reminders');
}

async function testCalendar() {
  logStart('Calendar');
  await safeCall('Calendar', 'getCalendarAuthorizationStatus', () => DiagnosticPlugin.getCalendarAuthorizationStatus());
  await safeCall('Calendar', 'isCalendarAuthorized', () => DiagnosticPlugin.isCalendarAuthorized());
  // Triggers permission dialog — runs last
  await safeCall('Calendar', 'requestCalendarAuthorization', () => DiagnosticPlugin.requestCalendarAuthorization());
  logDone('Calendar');
}

async function testContacts() {
  logStart('Contacts');
  await safeCall('Contacts', 'getAddressBookAuthorizationStatus', () => DiagnosticPlugin.getAddressBookAuthorizationStatus());
  await safeCall('Contacts', 'isAddressBookAuthorized', () => DiagnosticPlugin.isAddressBookAuthorized());
  // Triggers permission dialog — runs last
  await safeCall('Contacts', 'requestAddressBookAuthorization', () => DiagnosticPlugin.requestAddressBookAuthorization());
  logDone('Contacts');
}

async function testNFC() {
  // NFC is Android-only — all calls expected to return UNIMPLEMENTED on iOS
  logStart('NFC');
  await safeCall('NFC', 'isNFCPresent', () => DiagnosticPlugin.isNFCPresent());
  await safeCall('NFC', 'isNFCEnabled', () => DiagnosticPlugin.isNFCEnabled());
  await safeCall('NFC', 'isNFCAvailable', () => DiagnosticPlugin.isNFCAvailable());
  logDone('NFC');
}

// =============================================================
// MAIN RUNNER
// =============================================================

async function runAllTests() {
  setMarker('DIAG: RUNNING...');
  logInfo('================ iOS DIAGNOSTIC PLUGIN TEST START ================');

  await testLocation();
  await testBluetooth();
  await testCamera();
  await testNotifications();
  await testWifi();
  await testMicrophone();
  await testMotion();
  await testReminders();
  await testCalendar();
  await testContacts();
  await testNFC();

  logInfo('================ iOS DIAGNOSTIC PLUGIN TEST DONE ================');
  setMarker('DIAG: DONE — check Xcode console, filter by [DIAG]');
}

// =============================================================
// WEB COMPONENT / APP ENTRY
// =============================================================

window.customElements.define(
  'capacitor-welcome',
  class extends HTMLElement {
    constructor() {
      super();
      SplashScreen.hide();
      const root = this.attachShadow({ mode: 'open' });
      root.innerHTML = `
        <style>
          :host {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            display: block; width: 100%; height: 100%;
          }
          main { padding: 15px; }
          h1 { font-size: 1.2em; text-transform: uppercase; letter-spacing: 1px; }
          p { color: #333; font-size: 0.9em; }
          .button {
            display: inline-block; padding: 10px 16px;
            background-color: #73B5F6; color: #fff;
            font-size: 0.9em; border: 0; border-radius: 3px;
            text-decoration: none; cursor: pointer; margin: 4px 0;
          }
        </style>
        <div>
          <capacitor-welcome-titlebar><h1>Diagnostic Plugin Tests</h1></capacitor-welcome-titlebar>
          <main>
            <p>Tests run automatically on load. Check the Xcode console and filter by <strong>[DIAG]</strong> to see results.</p>
            <p><button class="button" id="run-tests">Re-run All Tests</button></p>
            <p><button class="button" id="take-photo">Test Camera UI</button></p>
            <p><img id="image" style="max-width: 100%"></p>
          </main>
        </div>
      `;
    }

    connectedCallback() {
      const self = this;

      self.shadowRoot.querySelector('#run-tests').addEventListener('click', () => {
        runAllTests();
      });

      self.shadowRoot.querySelector('#take-photo').addEventListener('click', async () => {
        try {
          const photo = await Camera.getPhoto({ resultType: 'uri' });
          const image = self.shadowRoot.querySelector('#image');
          if (image) image.src = photo.webPath;
        } catch (e) {
          console.warn('[DIAG][Camera] Camera UI cancelled or failed:', e);
        }
      });

      runAllTests();
    }
  }
);

window.customElements.define(
  'capacitor-welcome-titlebar',
  class extends HTMLElement {
    constructor() {
      super();
      const root = this.attachShadow({ mode: 'open' });
      root.innerHTML = `
        <style>
          :host {
            display: block; padding: 15px; text-align: center;
            background-color: #73B5F6;
          }
          ::slotted(h1) {
            margin: 0; font-size: 0.9em; font-weight: 600; color: #fff;
          }
        </style>
        <slot></slot>
      `;
    }
  }
);
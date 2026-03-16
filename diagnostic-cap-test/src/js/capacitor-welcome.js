import { SplashScreen } from '@capacitor/splash-screen';
import { Camera } from '@capacitor/camera';
import { registerPlugin } from '@capacitor/core';

const DiagnosticPlugin = registerPlugin('DiagnosticPlugin');

const LOG_PREFIX = 'DiagnosticTest';

// -----------------------
// Diagnostic helpers
// -----------------------

function log(section, label, obj) {
  console.log(`${LOG_PREFIX} --- ${section} -- ${label}`, JSON.stringify(obj));
}

function logInfo(section, message) {
  console.log(`${LOG_PREFIX} --- ${section} -- ${message}`);
}

function logError(section, label, error) {
  console.error(`${LOG_PREFIX} --- ${section} -- ${label}`, error);
}

async function safeCall(section, label, fn) {
  try {
    const res = await fn();
    log(section, label, res);
    return res;
  } catch (e) {
    logError(section, label, e);
    return null;
  }
}

function setMarker(text) {
  let el = document.getElementById('diag-smoke');
  if (!el) {
    el = document.createElement('div');
    el.id = 'diag-smoke';
    el.style.cssText =
      'position:fixed;top:0;left:0;z-index:99999;padding:6px;background:#000;color:#0f0;font-family:monospace;';
    document.body.appendChild(el);
  }
  el.textContent = text;
  document.title = text;
}

async function diagSmokeMarker() {
  setMarker('DIAG_PENDING');

  try {
    const result = await DiagnosticPlugin.getExternalSdCardDetails();
    const details = result?.details ?? [];
    const count = Array.isArray(details) ? details.length : 0;

    setMarker(`DIAG_OK:EXT_SD_COUNT=${count}`);
  } catch (e) {
    setMarker(`DIAG_FAIL:${e && e.message ? e.message : String(e)}`);
  }
}

async function runDiagnosticSmokeTests() {
  logInfo('General', '=== DiagnosticPlugin EXTERNAL STORAGE smoke test ===');

  // -----------------------
  // External Storage
  // -----------------------

  logInfo('ExternalStorage', '--- START ---');

  const external_storage = await safeCall(
    'ExternalStorage',
    'getExternalSdCardDetails',
    () => DiagnosticPlugin.getExternalSdCardDetails()
  );

  const details = external_storage?.details ?? [];

  if (Array.isArray(details)) {
    logInfo('ExternalStorage', `details_count=${details.length}`);

    details.forEach((detail, index) => {
      log('ExternalStorage', `detail[${index}]`, detail);
    });
  } else {
    logError(
      'ExternalStorage',
      'details shape',
      new Error('Expected result.details to be an array')
    );
  }

  /*
  // -----------------------
  // Wifi
  // -----------------------

  logInfo('Wifi', '--- START ---');

  await safeCall('Wifi', 'isWifiAvailable', () => DiagnosticPlugin.isWifiAvailable());
  await safeCall('Wifi', 'isWifiEnabled', () => DiagnosticPlugin.isWifiEnabled());

  // Manual settings navigation check:
  // await safeCall('Wifi', 'switchToWifiSettings', () =>
  //   DiagnosticPlugin.switchToWifiSettings()
  // );

  logInfo('Wifi', '--- SET STATE TESTS ---');

  await safeCall('Wifi', 'setWifiState(false)', () =>
    DiagnosticPlugin.setWifiState({ enable: false })
  );

  await safeCall('Wifi', 'setWifiState(true)', () =>
    DiagnosticPlugin.setWifiState({ enable: true })
  );

  await safeCall('Wifi', 'isWifiAvailable [after setWifiState]', () =>
    DiagnosticPlugin.isWifiAvailable()
  );

  await safeCall('Wifi', 'isWifiEnabled [after setWifiState]', () =>
    DiagnosticPlugin.isWifiEnabled()
  );
  */

  /*
  // -----------------------
  // Bluetooth
  // -----------------------

  let bluetoothListener = null;

  try {
    bluetoothListener = await DiagnosticPlugin.addListener('bluetoothStateChange', event => {
      log('Bluetooth', 'bluetoothStateChange', event);
    });
  } catch (e) {
    logError('Bluetooth', 'addListener(bluetoothStateChange)', e);
  }

  logInfo('Bluetooth', '--- START ---');

  await safeCall('Bluetooth', 'ensureBluetoothManager()', () =>
    DiagnosticPlugin.ensureBluetoothManager()
  );

  await safeCall('Bluetooth', 'getBluetoothState', () =>
    DiagnosticPlugin.getBluetoothState()
  );
  await safeCall('Bluetooth', 'isBluetoothAvailable', () =>
    DiagnosticPlugin.isBluetoothAvailable()
  );
  await safeCall('Bluetooth', 'isBluetoothEnabled', () =>
    DiagnosticPlugin.isBluetoothEnabled()
  );

  await safeCall('Bluetooth', 'hasBluetoothSupport', () =>
    DiagnosticPlugin.hasBluetoothSupport()
  );
  await safeCall('Bluetooth', 'hasBluetoothLESupport', () =>
    DiagnosticPlugin.hasBluetoothLESupport()
  );
  await safeCall('Bluetooth', 'hasBluetoothLEPeripheralSupport', () =>
    DiagnosticPlugin.hasBluetoothLEPeripheralSupport()
  );

  await safeCall('Bluetooth', 'getBluetoothAuthorizationStatus', () =>
    DiagnosticPlugin.getBluetoothAuthorizationStatus()
  );

  await safeCall('Bluetooth', 'requestBluetoothAuthorization()', () =>
    DiagnosticPlugin.requestBluetoothAuthorization()
  );

  await safeCall('Bluetooth', 'getBluetoothAuthorizationStatuses', () =>
    DiagnosticPlugin.getBluetoothAuthorizationStatuses()
  );

  if (bluetoothListener && bluetoothListener.remove) {
    try {
      await bluetoothListener.remove();
    } catch (e) {
      logError('Bluetooth', 'remove bluetooth listener', e);
    }
  }
  */

  /*
  // -----------------------
  // Camera
  // -----------------------

  logInfo('Camera', '--- START ---');

  await safeCall('Camera', 'isCameraPresent', () =>
    DiagnosticPlugin.isCameraPresent()
  );

  await safeCall('Camera', 'getCameraAuthorizationStatus [camera-only]', () =>
    DiagnosticPlugin.getCameraAuthorizationStatus({ storage: false })
  );

  await safeCall('Camera', 'getCameraAuthorizationStatuses [with-storage]', () =>
    DiagnosticPlugin.getCameraAuthorizationStatuses({ storage: true })
  );

  await safeCall('Camera', 'requestCameraAuthorization [camera-only]', () =>
    DiagnosticPlugin.requestCameraAuthorization({ storage: false })
  );

  await safeCall('Camera', 'requestCameraAuthorization [camera+storage]', () =>
    DiagnosticPlugin.requestCameraAuthorization({ storage: true })
  );
  */

  /*
  // -----------------------
  // Notifications
  // -----------------------

  logInfo('Notifications', '--- START ---');

  await safeCall('Notifications', 'getRemoteNotificationsAuthorizationStatus', () =>
    DiagnosticPlugin.getRemoteNotificationsAuthorizationStatus()
  );

  await safeCall('Notifications', 'isRemoteNotificationsEnabled', () =>
    DiagnosticPlugin.isRemoteNotificationsEnabled()
  );

  await safeCall('Notifications', 'getRemoteNotificationTypes', () =>
    DiagnosticPlugin.getRemoteNotificationTypes()
  );

  await safeCall('Notifications', 'isRegisteredForRemoteNotifications', () =>
    DiagnosticPlugin.isRegisteredForRemoteNotifications()
  );

  await safeCall('Notifications', 'requestRemoteNotificationsAuthorization', () =>
    DiagnosticPlugin.requestRemoteNotificationsAuthorization({
      types: ['alert', 'sound', 'badge'],
      omitRegistration: false,
    })
  );
  */

  await diagSmokeMarker();

  logInfo('General', '=== Done ===');
}

// -----------------------
// UI components
// -----------------------

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
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
        display: block;
        width: 100%;
        height: 100%;
      }
      h1, h2, h3, h4, h5 {
        text-transform: uppercase;
      }
      .button {
        display: inline-block;
        padding: 10px;
        background-color: #73B5F6;
        color: #fff;
        font-size: 0.9em;
        border: 0;
        border-radius: 3px;
        text-decoration: none;
        cursor: pointer;
      }
      main {
        padding: 15px;
      }
      main hr { height: 1px; background-color: #eee; border: 0; }
      main h1 {
        font-size: 1.4em;
        text-transform: uppercase;
        letter-spacing: 1px;
      }
      main h2 {
        font-size: 1.1em;
      }
      main h3 {
        font-size: 0.9em;
      }
      main p {
        color: #333;
      }
      main pre {
        white-space: pre-line;
      }
    </style>
    <div>
      <capacitor-welcome-titlebar>
        <h1>Capacitor</h1>
      </capacitor-welcome-titlebar>
      <main>
        <p>
          Capacitor makes it easy to build powerful apps for the app stores, mobile web (Progressive Web Apps), and desktop, all
          with a single code base.
        </p>
        <h2>Getting Started</h2>
        <p>
          You'll probably need a UI framework to build a full-featured app. Might we recommend
          <a target="_blank" href="http://ionicframework.com/">Ionic</a>?
        </p>
        <p>
          Visit <a href="https://capacitorjs.com">capacitorjs.com</a> for information
          on using native features, building plugins, and more.
        </p>
        <a href="https://capacitorjs.com" target="_blank" class="button">Read more</a>
        <h2>Tiny Demo</h2>
        <p>
          This demo shows how to call Capacitor plugins. Say cheese!
        </p>
        <p>
          <button class="button" id="take-photo">Take Photo</button>
        </p>
        <p>
          <img id="image" style="max-width: 100%">
        </p>
      </main>
    </div>
    `;
    }

    connectedCallback() {
      const self = this;

      self.shadowRoot.querySelector('#take-photo').addEventListener('click', async function () {
        try {
          const photo = await Camera.getPhoto({
            resultType: 'uri',
          });

          const image = self.shadowRoot.querySelector('#image');
          if (!image) {
            return;
          }

          image.src = photo.webPath;
        } catch (e) {
          console.warn('User cancelled', e);
        }
      });

      runDiagnosticSmokeTests();
    }
  },
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
        position: relative;
        display: block;
        padding: 15px 15px 15px 15px;
        text-align: center;
        background-color: #73B5F6;
      }
      ::slotted(h1) {
        margin: 0;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
        font-size: 0.9em;
        font-weight: 600;
        color: #fff;
      }
    </style>
    <slot></slot>
    `;
    }
  },
);
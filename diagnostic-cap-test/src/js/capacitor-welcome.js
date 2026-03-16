import { SplashScreen } from '@capacitor/splash-screen';
import { Camera } from '@capacitor/camera';

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

      self.shadowRoot.querySelector('#take-photo').addEventListener('click', async function (e) {
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
import { registerPlugin } from '@capacitor/core';

const DiagnosticPlugin = registerPlugin('DiagnosticPlugin');

const LOG_PREFIX = 'DiagnosticTest';

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
    const available = await DiagnosticPlugin.isWifiAvailable();
    const enabled = await DiagnosticPlugin.isWifiEnabled();

    setMarker(
      `DIAG_OK:WIFI_AVAIL=${available?.available ?? false}|WIFI_EN=${enabled?.enabled ?? false}`
    );
  } catch (e) {
    setMarker(`DIAG_FAIL:${e && e.message ? e.message : String(e)}`);
  }
}

(async () => {
  logInfo('General', '=== DiagnosticPlugin WIFI smoke test ===');

  /*
  // -----------------------
  // Bluetooth (temporarily disabled)
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

  logInfo('Bluetooth', '--- AUTH BEFORE REQUEST ---');
  await safeCall('Bluetooth', 'getBluetoothAuthorizationStatus [before]', () =>
    DiagnosticPlugin.getBluetoothAuthorizationStatus()
  );

  logInfo('Bluetooth', '--- REQUEST AUTH ---');
  await safeCall('Bluetooth', 'requestBluetoothAuthorization()', () =>
    DiagnosticPlugin.requestBluetoothAuthorization()
  );

  logInfo('Bluetooth', '--- AUTH AFTER REQUEST ---');
  await safeCall('Bluetooth', 'getBluetoothAuthorizationStatus [after]', () =>
    DiagnosticPlugin.getBluetoothAuthorizationStatus()
  );

  await safeCall('Bluetooth', 'getBluetoothAuthorizationStatuses [after]', () =>
    DiagnosticPlugin.getBluetoothAuthorizationStatuses()
  );
  */

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

  // On Android 10+ these calls are expected to reject because the platform
  // no longer allows normal third-party apps to change Wi-Fi state directly.
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

  /*
  // -----------------------
  // Camera
  // -----------------------

  logInfo('Camera', '--- START ---');

  await safeCall('Camera', 'isCameraPresent', () =>
    DiagnosticPlugin.isCameraPresent()
  );

  logInfo('Camera', '--- AUTH BEFORE REQUEST (camera only) ---');
  await safeCall('Camera', 'getCameraAuthorizationStatus [before][camera-only]', () =>
    DiagnosticPlugin.getCameraAuthorizationStatus({ storage: false })
  );

  await safeCall('Camera', 'getCameraAuthorizationStatuses [before][with-storage]', () =>
    DiagnosticPlugin.getCameraAuthorizationStatuses({ storage: true })
  );

  logInfo('Camera', '--- REQUEST AUTH (camera only) ---');
  await safeCall('Camera', 'requestCameraAuthorization [camera-only]', () =>
    DiagnosticPlugin.requestCameraAuthorization({ storage: false })
  );

  logInfo('Camera', '--- AUTH AFTER REQUEST (camera only) ---');
  await safeCall('Camera', 'getCameraAuthorizationStatus [after][camera-only]', () =>
    DiagnosticPlugin.getCameraAuthorizationStatus({ storage: false })
  );

  logInfo('Camera', '--- REQUEST AUTH (camera + storage) ---');
  await safeCall('Camera', 'requestCameraAuthorization [camera+storage]', () =>
    DiagnosticPlugin.requestCameraAuthorization({ storage: true })
  );

  await safeCall('Camera', 'getCameraAuthorizationStatus [after][camera+storage]', () =>
    DiagnosticPlugin.getCameraAuthorizationStatus({ storage: true })
  );

  await safeCall('Camera', 'getCameraAuthorizationStatuses [after][camera+storage]', () =>
    DiagnosticPlugin.getCameraAuthorizationStatuses({ storage: true })
  );

  // -----------------------
  // Notifications
  // -----------------------

  logInfo('Notifications', '--- START ---');

  logInfo('Notifications', '--- BEFORE REQUEST ---');
  await safeCall('Notifications', 'getRemoteNotificationsAuthorizationStatus [before]', () =>
    DiagnosticPlugin.getRemoteNotificationsAuthorizationStatus()
  );

  await safeCall('Notifications', 'isRemoteNotificationsEnabled [before]', () =>
    DiagnosticPlugin.isRemoteNotificationsEnabled()
  );

  await safeCall('Notifications', 'getRemoteNotificationTypes [before]', () =>
    DiagnosticPlugin.getRemoteNotificationTypes()
  );

  await safeCall('Notifications', 'isRegisteredForRemoteNotifications [before]', () =>
    DiagnosticPlugin.isRegisteredForRemoteNotifications()
  );

  logInfo('Notifications', '--- REQUEST AUTH ---');
  await safeCall('Notifications', 'requestRemoteNotificationsAuthorization', () =>
    DiagnosticPlugin.requestRemoteNotificationsAuthorization({
      types: ['alert', 'sound', 'badge'],
      omitRegistration: false,
    })
  );

  logInfo('Notifications', '--- AFTER REQUEST ---');
  await safeCall('Notifications', 'getRemoteNotificationsAuthorizationStatus [after]', () =>
    DiagnosticPlugin.getRemoteNotificationsAuthorizationStatus()
  );

  await safeCall('Notifications', 'isRemoteNotificationsEnabled [after]', () =>
    DiagnosticPlugin.isRemoteNotificationsEnabled()
  );

  await safeCall('Notifications', 'getRemoteNotificationTypes [after]', () =>
    DiagnosticPlugin.getRemoteNotificationTypes()
  );

  await safeCall('Notifications', 'isRegisteredForRemoteNotifications [after]', () =>
    DiagnosticPlugin.isRegisteredForRemoteNotifications()
  );

  // Optional manual check:
  // await safeCall('Notifications', 'switchToNotificationSettings', () =>
  //   DiagnosticPlugin.switchToNotificationSettings()
  // );
  */

  await diagSmokeMarker();

  /*
  if (bluetoothListener && bluetoothListener.remove) {
    try {
      await bluetoothListener.remove();
    } catch (e) {
      logError('Bluetooth', 'remove bluetooth listener', e);
    }
  }
  */

  logInfo('General', '=== Done ===');
})();
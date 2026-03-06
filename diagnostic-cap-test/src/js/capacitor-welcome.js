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

function log(label, obj) {
  console.log(label, JSON.stringify(obj));
}

async function safeCall(label, fn) {
  try {
    const res = await fn();
    log(label, res);
    return res;
  } catch (e) {
    console.error(label, e);
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
    const location = await DiagnosticPlugin.getLocationAuthorizationStatus();
    const bluetooth = await DiagnosticPlugin.getBluetoothState();
    setMarker(
      `DIAG_OK:LOC=${location?.status ?? 'unknown'}|BT=${bluetooth?.state ?? 'unknown'}`
    );
  } catch (e) {
    setMarker(`DIAG_FAIL:${e && e.message ? e.message : String(e)}`);
  }
}

(async () => {
  console.log('=== DiagnosticPlugin LOCATION + BLUETOOTH smoke test ===');

  // -----------------------
  // Bluetooth event listener
  // -----------------------
  let bluetoothListener = null;

  try {
    bluetoothListener = await DiagnosticPlugin.addListener('bluetoothStateChange', event => {
      console.log('bluetoothStateChange', JSON.stringify(event));
    });
  } catch (e) {
    console.error('addListener(bluetoothStateChange)', e);
  }

  // -----------------------
  // Location
  // -----------------------
  console.log('--- LOCATION ---');

  await safeCall('getLocationAuthorizationStatus', () =>
    DiagnosticPlugin.getLocationAuthorizationStatus()
  );

  await safeCall('getLocationMode', () => DiagnosticPlugin.getLocationMode());
  await safeCall('isLocationEnabled', () => DiagnosticPlugin.isLocationEnabled());
  await safeCall('isLocationAvailable', () => DiagnosticPlugin.isLocationAvailable());

  await safeCall('isGpsLocationEnabled', () => DiagnosticPlugin.isGpsLocationEnabled());
  await safeCall('isNetworkLocationEnabled', () => DiagnosticPlugin.isNetworkLocationEnabled());
  await safeCall('isGpsLocationAvailable', () => DiagnosticPlugin.isGpsLocationAvailable());
  await safeCall('isNetworkLocationAvailable', () => DiagnosticPlugin.isNetworkLocationAvailable());

  await safeCall('isCompassAvailable', () => DiagnosticPlugin.isCompassAvailable());

  await safeCall('isLocationAuthorized', () => DiagnosticPlugin.isLocationAuthorized());
  await safeCall('getLocationAccuracyAuthorization', () =>
    DiagnosticPlugin.getLocationAccuracyAuthorization()
  );
  await safeCall(
    'requestTemporaryFullAccuracyAuthorization({purpose:"DiagCapTempFullAccuracy"})',
    () =>
      DiagnosticPlugin.requestTemporaryFullAccuracyAuthorization({
        purpose: 'DiagCapTempFullAccuracy',
      })
  );

  console.log('--- Request WHEN_IN_USE ---');
  await safeCall('requestLocationAuthorization({mode:"when_in_use"})', () =>
    DiagnosticPlugin.requestLocationAuthorization({ mode: 'when_in_use' })
  );

  console.log('--- Request ALWAYS ---');
  await safeCall('requestLocationAuthorization({mode:"always"})', () =>
    DiagnosticPlugin.requestLocationAuthorization({ mode: 'always' })
  );

  await safeCall('openLocationSettings()', () => DiagnosticPlugin.openLocationSettings());
  await safeCall('switchToLocationSettings()', () => DiagnosticPlugin.switchToLocationSettings());

  // -----------------------
  // Bluetooth
  // -----------------------
  console.log('--- BLUETOOTH ---');

  await safeCall('ensureBluetoothManager()', () => DiagnosticPlugin.ensureBluetoothManager());

  await safeCall('getBluetoothState', () => DiagnosticPlugin.getBluetoothState());
  await safeCall('isBluetoothAvailable', () => DiagnosticPlugin.isBluetoothAvailable());
  await safeCall('isBluetoothEnabled', () => DiagnosticPlugin.isBluetoothEnabled());

  await safeCall('hasBluetoothSupport', () => DiagnosticPlugin.hasBluetoothSupport());
  await safeCall('hasBluetoothLESupport', () => DiagnosticPlugin.hasBluetoothLESupport());
  await safeCall('hasBluetoothLEPeripheralSupport', () =>
    DiagnosticPlugin.hasBluetoothLEPeripheralSupport()
  );

  await safeCall('getBluetoothAuthorizationStatus', () =>
    DiagnosticPlugin.getBluetoothAuthorizationStatus()
  );

  await safeCall('getBluetoothAuthorizationStatuses', () =>
    DiagnosticPlugin.getBluetoothAuthorizationStatuses()
  );

  await safeCall('requestBluetoothAuthorization()', () =>
    DiagnosticPlugin.requestBluetoothAuthorization()
  );

  await safeCall('requestBluetoothAuthorization({permissions:["BLUETOOTH_SCAN"]})', () =>
    DiagnosticPlugin.requestBluetoothAuthorization({
      permissions: ['BLUETOOTH_SCAN'],
    })
  );

  await safeCall('setBluetoothState({enable:true})', () =>
    DiagnosticPlugin.setBluetoothState({ enable: true })
  );

  await safeCall('setBluetoothState({enable:false})', () =>
    DiagnosticPlugin.setBluetoothState({ enable: false })
  );

  await safeCall('switchToBluetoothSettings()', () =>
    DiagnosticPlugin.switchToBluetoothSettings()
  );

  // CI marker
  await diagSmokeMarker();

  if (bluetoothListener && bluetoothListener.remove) {
    try {
      await bluetoothListener.remove();
    } catch (e) {
      console.error('remove bluetooth listener', e);
    }
  }

  console.log('=== Done ===');
})();
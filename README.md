# diagnostic-capacitor

A Capacitor port of the [cordova-diagnostic-plugin](https://github.com/dpa99c/cordova-diagnostic-plugin) for OutSystems ODC mobile apps.

This plugin exposes device permission and hardware diagnostic APIs across Android and iOS, with behavior and return values that match the original Cordova plugin. It was built to support dual-stack operation in the DeviceDiagnostic Library; it resolves to the same status strings so existing app logic doesn't need to change.

---

## What this is

OutSystems ODC apps can be built with either Cordova (MABS 11) or Capacitor (MABS 12+). The `DeviceDiagnostic` ODC Library used to only build using the Cordova plugin's JavaScript API. When the build target switches to Capacitor, those Cordova calls stop working.

This plugin bridges that gap. It exposes the same method names, parameters, and return values as the original Cordova plugin, but is built as a proper Capacitor plugin so it works in Capacitor builds.

---

## Platform support

| Module | Android | iOS |
|---|---|---|
| Location | ✅ | ✅ |
| Bluetooth | ✅ | ✅ |
| Camera | ✅ | ✅ |
| Notifications | ✅ | ✅ |
| WiFi | ✅ | ✅ |
| External Storage | ✅ | ❌ |
| NFC | ✅ | ❌ |
| Microphone | ❌ | ✅ |
| Motion | ❌ | ✅ |
| Reminders | ❌ | ✅ |
| Calendar | ❌ | ✅ |
| Contacts | ❌ | ✅ |

Modules listed as `❌` return `not_implemented` on that platform, matching the original Cordova plugin's behavior.

---

## Architecture

Single plugin, thin bridge, feature modules carry the logic.

```
DiagnosticPlugin (bridge)
├── LocationModule
├── BluetoothModule
├── CameraModule
├── NotificationsModule
├── WifiModule
├── ExternalStorageModule   (Android only)
├── NfcModule               (Android only)
├── MicrophoneModule        (iOS only)
├── MotionModule            (iOS only)
├── RemindersModule         (iOS only)
├── CalendarModule          (iOS only)
└── ContactsModule          (iOS only)
```

On iOS, `DiagnosticPlugin.swift` is a pure passthrough — every `@objc func` is a one-liner delegating to the relevant module. All logic lives in the modules.

On Android, `DiagnosticPlugin.java` also delegates to modules, but additionally handles `@PermissionCallback` methods since those must live on the plugin class itself (Capacitor requirement).

### iOS SPM target split

SPM doesn't allow mixed ObjC/Swift in a single target. The plugin uses two targets:

- `DiagnosticPluginObjC` — contains `Plugin.m` (the ObjC bridge registrations)
- `DiagnosticPlugin` — contains all Swift source files

Both are declared in `Package.swift` and linked together. The consuming app's `CapApp-SPM.swift` imports `DiagnosticPlugin`.

---

## Return value conventions

Status strings match the original Cordova plugin exactly:

**Authorization / permission status:**
`not_determined`, `denied`, `denied_always`, `granted`, `authorized_when_in_use`, `authorized_always`, `limited`, `not_requested`

**Bluetooth / NFC state:**
`powered_on`, `powered_off`, `powering_on`, `powering_off`, `unknown`

**Location mode (Android):**
`high_accuracy`, `device_only`, `battery_saving`, `location_off`, `unknown`

**Location accuracy (iOS):**
`full`, `reduced`

---

## Android-specific notes

**Bluetooth permissions (Android 12+):** The three runtime permissions (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_ADVERTISE`) are tracked individually in SharedPreferences under the `DiagnosticBluetoothPrefs` key. This is required to correctly distinguish `not_determined` from `denied` before the user has been prompted.

**Camera storage (Android 13/14):** The media permission model changed across API levels. Android 13 uses `READ_MEDIA_IMAGES`/`READ_MEDIA_VIDEO`. Android 14 adds `READ_MEDIA_VISUAL_USER_SELECTED` which maps to a `LIMITED` status when the user selects specific photos.

**WiFi state toggle:** `setWifiState()` is only functional on Android 9 and below. Android 10+ restricts `WifiManager.setWifiEnabled()` for third-party apps — the call will reject on those versions. This matches Cordova behavior.

**Bluetooth state toggle:** `setBluetoothState()` is only functional on Android 12 and below. `BluetoothAdapter.enable/disable()` were removed as a public API in Android 13. The call rejects on Android 13+.

---

## iOS-specific notes

**Local network permission:** iOS doesn't have a direct API to read local network permission status. The probe works by attempting to publish a Bonjour service and observing whether it succeeds or gets blocked with `EPERM`. Results are cached to UserDefaults. If the probe times out (default 2 seconds), `indeterminate` (-2) is returned.

**Motion permission:** `requestMotionAuthorization()` can only be called once per app installation. Calling it a second time rejects immediately — iOS won't re-prompt. Use `getMotionAuthorizationStatus()` to check status without triggering a prompt.

**Bluetooth authorization:** Instantiating `CBCentralManager` triggers the Bluetooth usage prompt on iOS 13+. The plugin defers this until `ensureBluetoothManager()` or `requestBluetoothAuthorization()` is called.

**Location accuracy (iOS 14+):** `getLocationAccuracyAuthorization()` returns `"full"` or `"reduced"`. `requestTemporaryFullAccuracyAuthorization()` requires a purpose key matching an entry in `NSLocationTemporaryUsageDescriptionDictionary` in `Info.plist`.

**Notifications (iOS 16+):** `switchToNotificationSettings()` uses `UIApplication.openNotificationSettingsURLString` on iOS 16+ for a direct link to the notification settings page. Falls back to the generic settings URL on older versions.

**Calendar write-only access (iOS 17+):** `.writeOnly` is treated as `"granted"` in CalendarModule (matches Cordova behavior). In RemindersModule, `.writeOnly` is treated as `"denied"` — write-only isn't sufficient for reminders access.
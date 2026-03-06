# @noesis/diagnostic-capacitor

Capacitor implementation of the Cordova Diagnostic plugin for checking device permissions and system settings.

## Install

```bash
npm install @noesis/diagnostic-capacitor
npx cap sync
```

## API

<docgen-index>

* [`getLocationAuthorizationStatus()`](#getlocationauthorizationstatus)
* [`requestLocationAuthorization(...)`](#requestlocationauthorization)
* [`isLocationEnabled()`](#islocationenabled)
* [`openLocationSettings()`](#openlocationsettings)
* [`isLocationAvailable()`](#islocationavailable)
* [`getLocationMode()`](#getlocationmode)
* [`isGpsLocationEnabled()`](#isgpslocationenabled)
* [`isNetworkLocationEnabled()`](#isnetworklocationenabled)
* [`isGpsLocationAvailable()`](#isgpslocationavailable)
* [`isNetworkLocationAvailable()`](#isnetworklocationavailable)
* [`switchToLocationSettings()`](#switchtolocationsettings)
* [`isCompassAvailable()`](#iscompassavailable)
* [`isLocationAuthorized()`](#islocationauthorized)
* [`getLocationAccuracyAuthorization()`](#getlocationaccuracyauthorization)
* [`requestTemporaryFullAccuracyAuthorization(...)`](#requesttemporaryfullaccuracyauthorization)
* [`switchToBluetoothSettings()`](#switchtobluetoothsettings)
* [`isBluetoothAvailable()`](#isbluetoothavailable)
* [`isBluetoothEnabled()`](#isbluetoothenabled)
* [`hasBluetoothSupport()`](#hasbluetoothsupport)
* [`hasBluetoothLESupport()`](#hasbluetoothlesupport)
* [`hasBluetoothLEPeripheralSupport()`](#hasbluetoothleperipheralsupport)
* [`setBluetoothState(...)`](#setbluetoothstate)
* [`getBluetoothState()`](#getbluetoothstate)
* [`getBluetoothAuthorizationStatuses()`](#getbluetoothauthorizationstatuses)
* [`requestBluetoothAuthorization(...)`](#requestbluetoothauthorization)
* [`ensureBluetoothManager()`](#ensurebluetoothmanager)
* [`getBluetoothAuthorizationStatus()`](#getbluetoothauthorizationstatus)
* [`addListener('bluetoothStateChange', ...)`](#addlistenerbluetoothstatechange-)
* [`removeAllListeners()`](#removealllisteners)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### getLocationAuthorizationStatus()

```typescript
getLocationAuthorizationStatus() => Promise<{ status: string; }>
```

Returns the current location authorization status (Cordova parity strings).

**Returns:** <code>Promise&lt;{ status: string; }&gt;</code>

--------------------


### requestLocationAuthorization(...)

```typescript
requestLocationAuthorization(options?: { mode?: "always" | "when_in_use" | undefined; } | undefined) => Promise<{ status: string; }>
```

Requests location authorization.
`mode` maps to Cordova semantics: 'always' | 'when_in_use'

| Param         | Type                                               |
| ------------- | -------------------------------------------------- |
| **`options`** | <code>{ mode?: 'always' \| 'when_in_use'; }</code> |

**Returns:** <code>Promise&lt;{ status: string; }&gt;</code>

--------------------


### isLocationEnabled()

```typescript
isLocationEnabled() => Promise<{ enabled: boolean; }>
```

True if location services are enabled at OS level.

**Returns:** <code>Promise&lt;{ enabled: boolean; }&gt;</code>

--------------------


### openLocationSettings()

```typescript
openLocationSettings() => Promise<void>
```

Opens the OS-level Location settings screen (best-effort per platform).

--------------------


### isLocationAvailable()

```typescript
isLocationAvailable() => Promise<{ available: boolean; }>
```

True if location is available for use (authorization + services enabled, per Cordova behavior).

**Returns:** <code>Promise&lt;{ available: boolean; }&gt;</code>

--------------------


### getLocationMode()

```typescript
getLocationMode() => Promise<{ mode: string; }>
```

Returns the current location mode (platform-specific string, Cordova parity).

**Returns:** <code>Promise&lt;{ mode: string; }&gt;</code>

--------------------


### isGpsLocationEnabled()

```typescript
isGpsLocationEnabled() => Promise<{ enabled: boolean; }>
```

True if GPS provider is enabled (Android-specific; iOS returns best-effort parity).

**Returns:** <code>Promise&lt;{ enabled: boolean; }&gt;</code>

--------------------


### isNetworkLocationEnabled()

```typescript
isNetworkLocationEnabled() => Promise<{ enabled: boolean; }>
```

True if Network provider is enabled (Android-specific; iOS returns best-effort parity).

**Returns:** <code>Promise&lt;{ enabled: boolean; }&gt;</code>

--------------------


### isGpsLocationAvailable()

```typescript
isGpsLocationAvailable() => Promise<{ available: boolean; }>
```

True if GPS location is available (Android-specific; iOS returns best-effort parity).

**Returns:** <code>Promise&lt;{ available: boolean; }&gt;</code>

--------------------


### isNetworkLocationAvailable()

```typescript
isNetworkLocationAvailable() => Promise<{ available: boolean; }>
```

True if Network location is available (Android-specific; iOS returns best-effort parity).

**Returns:** <code>Promise&lt;{ available: boolean; }&gt;</code>

--------------------


### switchToLocationSettings()

```typescript
switchToLocationSettings() => Promise<void>
```

Opens the OS-level Location settings screen (Cordova-style method naming).

--------------------


### isCompassAvailable()

```typescript
isCompassAvailable() => Promise<{ available: boolean; }>
```

True if device has a compass / magnetometer available.

**Returns:** <code>Promise&lt;{ available: boolean; }&gt;</code>

--------------------


### isLocationAuthorized()

```typescript
isLocationAuthorized() => Promise<{ value: boolean; }>
```

True if app is authorized to use location services (authorization only).

**Returns:** <code>Promise&lt;{ value: boolean; }&gt;</code>

--------------------


### getLocationAccuracyAuthorization()

```typescript
getLocationAccuracyAuthorization() => Promise<{ value: 'full' | 'reduced'; }>
```

iOS-only accuracy authorization.
Returns "full" or "reduced" (iOS 14+); other platforms default to "full".

**Returns:** <code>Promise&lt;{ value: 'full' | 'reduced'; }&gt;</code>

--------------------


### requestTemporaryFullAccuracyAuthorization(...)

```typescript
requestTemporaryFullAccuracyAuthorization(options: { purpose: string; }) => Promise<{ value: 'full' | 'reduced'; }>
```

iOS-only temporary full accuracy request (iOS 14+).
`purpose` must match a key in Info.plist (NSLocationTemporaryUsageDescriptionDictionary).

| Param         | Type                              |
| ------------- | --------------------------------- |
| **`options`** | <code>{ purpose: string; }</code> |

**Returns:** <code>Promise&lt;{ value: 'full' | 'reduced'; }&gt;</code>

--------------------


### switchToBluetoothSettings()

```typescript
switchToBluetoothSettings() => Promise<void>
```

Opens OS Bluetooth settings screen.

--------------------


### isBluetoothAvailable()

```typescript
isBluetoothAvailable() => Promise<{ available: boolean; }>
```

True if device supports Bluetooth and Bluetooth is enabled.

**Returns:** <code>Promise&lt;{ available: boolean; }&gt;</code>

--------------------


### isBluetoothEnabled()

```typescript
isBluetoothEnabled() => Promise<{ enabled: boolean; }>
```

True if Bluetooth adapter exists and is enabled.

**Returns:** <code>Promise&lt;{ enabled: boolean; }&gt;</code>

--------------------


### hasBluetoothSupport()

```typescript
hasBluetoothSupport() => Promise<{ supported: boolean; }>
```

True if device has FEATURE_BLUETOOTH.

**Returns:** <code>Promise&lt;{ supported: boolean; }&gt;</code>

--------------------


### hasBluetoothLESupport()

```typescript
hasBluetoothLESupport() => Promise<{ supported: boolean; }>
```

True if device has FEATURE_BLUETOOTH_LE.

**Returns:** <code>Promise&lt;{ supported: boolean; }&gt;</code>

--------------------


### hasBluetoothLEPeripheralSupport()

```typescript
hasBluetoothLEPeripheralSupport() => Promise<{ supported: boolean; }>
```

True if adapter supports multiple advertisement (peripheral mode).

**Returns:** <code>Promise&lt;{ supported: boolean; }&gt;</code>

--------------------


### setBluetoothState(...)

```typescript
setBluetoothState(options: { enable: boolean; }) => Promise<void>
```

Attempts to enable/disable Bluetooth.
Android 13+ rejects (matches Cordova behavior).

| Param         | Type                              |
| ------------- | --------------------------------- |
| **`options`** | <code>{ enable: boolean; }</code> |

--------------------


### getBluetoothState()

```typescript
getBluetoothState() => Promise<{ state: string; }>
```

Returns Bluetooth hardware state string (Cordova parity):
Android: unknown|powered_on|powered_off|powering_on|powering_off
iOS: powered_on|powered_off|unauthorized|unsupported|resetting|unknown

**Returns:** <code>Promise&lt;{ state: string; }&gt;</code>

--------------------


### getBluetoothAuthorizationStatuses()

```typescript
getBluetoothAuthorizationStatuses() => Promise<{ statuses: Record<string, string>; }>
```

Android: returns per-permission status map for BLUETOOTH_* runtime permissions (SDK&gt;=31).
iOS: returns a single `authorization` string.

**Returns:** <code>Promise&lt;{ statuses: <a href="#record">Record</a>&lt;string, string&gt;; }&gt;</code>

--------------------


### requestBluetoothAuthorization(...)

```typescript
requestBluetoothAuthorization(options?: { permissions?: ("BLUETOOTH_ADVERTISE" | "BLUETOOTH_CONNECT" | "BLUETOOTH_SCAN")[] | undefined; } | undefined) => Promise<{ status: string; }>
```

Android: request BLUETOOTH_* permissions (optionally specify which).
iOS: triggers permission prompt if not determined.

| Param         | Type                                                                                                 |
| ------------- | ---------------------------------------------------------------------------------------------------- |
| **`options`** | <code>{ permissions?: ('BLUETOOTH_ADVERTISE' \| 'BLUETOOTH_CONNECT' \| 'BLUETOOTH_SCAN')[]; }</code> |

**Returns:** <code>Promise&lt;{ status: string; }&gt;</code>

--------------------


### ensureBluetoothManager()

```typescript
ensureBluetoothManager() => Promise<void>
```

iOS-only explicit init of Bluetooth manager (parity with Cordova).
Android is a no-op.

--------------------


### getBluetoothAuthorizationStatus()

```typescript
getBluetoothAuthorizationStatus() => Promise<{ status: string; }>
```

iOS-only single authorization status string (granted|denied|not_determined).
Android returns derived status (granted if all requested perms granted, otherwise denied/denied_always).

**Returns:** <code>Promise&lt;{ status: string; }&gt;</code>

--------------------


### addListener('bluetoothStateChange', ...)

```typescript
addListener(eventName: 'bluetoothStateChange', listenerFunc: (event: { state: string; }) => void) => Promise<PluginListenerHandle>
```

Bluetooth state change event. Fired when underlying OS BT state changes.

| Param              | Type                                                |
| ------------------ | --------------------------------------------------- |
| **`eventName`**    | <code>'bluetoothStateChange'</code>                 |
| **`listenerFunc`** | <code>(event: { state: string; }) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### removeAllListeners()

```typescript
removeAllListeners() => Promise<void>
```

--------------------


### Interfaces


#### Array

| Prop         | Type                | Description                                                                                            |
| ------------ | ------------------- | ------------------------------------------------------------------------------------------------------ |
| **`length`** | <code>number</code> | Gets or sets the length of the array. This is a number one higher than the highest index in the array. |

| Method             | Signature                                                                                                                     | Description                                                                                                                                                                                                                                 |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **toString**       | () =&gt; string                                                                                                               | Returns a string representation of an array.                                                                                                                                                                                                |
| **toLocaleString** | () =&gt; string                                                                                                               | Returns a string representation of an array. The elements are converted to string using their toLocalString methods.                                                                                                                        |
| **pop**            | () =&gt; T \| undefined                                                                                                       | Removes the last element from an array and returns it. If the array is empty, undefined is returned and the array is not modified.                                                                                                          |
| **push**           | (...items: T[]) =&gt; number                                                                                                  | Appends new elements to the end of an array, and returns the new length of the array.                                                                                                                                                       |
| **concat**         | (...items: <a href="#concatarray">ConcatArray</a>&lt;T&gt;[]) =&gt; T[]                                                       | Combines two or more arrays. This method returns a new array without modifying any existing arrays.                                                                                                                                         |
| **concat**         | (...items: (T \| <a href="#concatarray">ConcatArray</a>&lt;T&gt;)[]) =&gt; T[]                                                | Combines two or more arrays. This method returns a new array without modifying any existing arrays.                                                                                                                                         |
| **join**           | (separator?: string \| undefined) =&gt; string                                                                                | Adds all the elements of an array into a string, separated by the specified separator string.                                                                                                                                               |
| **reverse**        | () =&gt; T[]                                                                                                                  | Reverses the elements in an array in place. This method mutates the array and returns a reference to the same array.                                                                                                                        |
| **shift**          | () =&gt; T \| undefined                                                                                                       | Removes the first element from an array and returns it. If the array is empty, undefined is returned and the array is not modified.                                                                                                         |
| **slice**          | (start?: number \| undefined, end?: number \| undefined) =&gt; T[]                                                            | Returns a copy of a section of an array. For both start and end, a negative index can be used to indicate an offset from the end of the array. For example, -2 refers to the second to last element of the array.                           |
| **sort**           | (compareFn?: ((a: T, b: T) =&gt; number) \| undefined) =&gt; this                                                             | Sorts an array in place. This method mutates the array and returns a reference to the same array.                                                                                                                                           |
| **splice**         | (start: number, deleteCount?: number \| undefined) =&gt; T[]                                                                  | Removes elements from an array and, if necessary, inserts new elements in their place, returning the deleted elements.                                                                                                                      |
| **splice**         | (start: number, deleteCount: number, ...items: T[]) =&gt; T[]                                                                 | Removes elements from an array and, if necessary, inserts new elements in their place, returning the deleted elements.                                                                                                                      |
| **unshift**        | (...items: T[]) =&gt; number                                                                                                  | Inserts new elements at the start of an array, and returns the new length of the array.                                                                                                                                                     |
| **indexOf**        | (searchElement: T, fromIndex?: number \| undefined) =&gt; number                                                              | Returns the index of the first occurrence of a value in an array, or -1 if it is not present.                                                                                                                                               |
| **lastIndexOf**    | (searchElement: T, fromIndex?: number \| undefined) =&gt; number                                                              | Returns the index of the last occurrence of a specified value in an array, or -1 if it is not present.                                                                                                                                      |
| **every**          | &lt;S extends T&gt;(predicate: (value: T, index: number, array: T[]) =&gt; value is S, thisArg?: any) =&gt; this is S[]       | Determines whether all the members of an array satisfy the specified test.                                                                                                                                                                  |
| **every**          | (predicate: (value: T, index: number, array: T[]) =&gt; unknown, thisArg?: any) =&gt; boolean                                 | Determines whether all the members of an array satisfy the specified test.                                                                                                                                                                  |
| **some**           | (predicate: (value: T, index: number, array: T[]) =&gt; unknown, thisArg?: any) =&gt; boolean                                 | Determines whether the specified callback function returns true for any element of an array.                                                                                                                                                |
| **forEach**        | (callbackfn: (value: T, index: number, array: T[]) =&gt; void, thisArg?: any) =&gt; void                                      | Performs the specified action for each element in an array.                                                                                                                                                                                 |
| **map**            | &lt;U&gt;(callbackfn: (value: T, index: number, array: T[]) =&gt; U, thisArg?: any) =&gt; U[]                                 | Calls a defined callback function on each element of an array, and returns an array that contains the results.                                                                                                                              |
| **filter**         | &lt;S extends T&gt;(predicate: (value: T, index: number, array: T[]) =&gt; value is S, thisArg?: any) =&gt; S[]               | Returns the elements of an array that meet the condition specified in a callback function.                                                                                                                                                  |
| **filter**         | (predicate: (value: T, index: number, array: T[]) =&gt; unknown, thisArg?: any) =&gt; T[]                                     | Returns the elements of an array that meet the condition specified in a callback function.                                                                                                                                                  |
| **reduce**         | (callbackfn: (previousValue: T, currentValue: T, currentIndex: number, array: T[]) =&gt; T) =&gt; T                           | Calls the specified callback function for all the elements in an array. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function.                      |
| **reduce**         | (callbackfn: (previousValue: T, currentValue: T, currentIndex: number, array: T[]) =&gt; T, initialValue: T) =&gt; T          |                                                                                                                                                                                                                                             |
| **reduce**         | &lt;U&gt;(callbackfn: (previousValue: U, currentValue: T, currentIndex: number, array: T[]) =&gt; U, initialValue: U) =&gt; U | Calls the specified callback function for all the elements in an array. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function.                      |
| **reduceRight**    | (callbackfn: (previousValue: T, currentValue: T, currentIndex: number, array: T[]) =&gt; T) =&gt; T                           | Calls the specified callback function for all the elements in an array, in descending order. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function. |
| **reduceRight**    | (callbackfn: (previousValue: T, currentValue: T, currentIndex: number, array: T[]) =&gt; T, initialValue: T) =&gt; T          |                                                                                                                                                                                                                                             |
| **reduceRight**    | &lt;U&gt;(callbackfn: (previousValue: U, currentValue: T, currentIndex: number, array: T[]) =&gt; U, initialValue: U) =&gt; U | Calls the specified callback function for all the elements in an array, in descending order. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function. |


#### ConcatArray

| Prop         | Type                |
| ------------ | ------------------- |
| **`length`** | <code>number</code> |

| Method    | Signature                                                          |
| --------- | ------------------------------------------------------------------ |
| **join**  | (separator?: string \| undefined) =&gt; string                     |
| **slice** | (start?: number \| undefined, end?: number \| undefined) =&gt; T[] |


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |


### Type Aliases


#### Record

Construct a type with a set of properties K of type T

<code>{ [P in K]: T; }</code>

</docgen-api>

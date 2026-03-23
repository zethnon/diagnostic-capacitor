package com.noesis.diagnostic.modules;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.nfc.NfcAdapter;
import android.nfc.NfcManager;
import android.os.Build;
import android.provider.Settings;
import android.util.Log;

import com.getcapacitor.JSObject;
import com.getcapacitor.PluginCall;
import com.noesis.diagnostic.DiagnosticPlugin;

public class NfcModule {

    public interface NfcStateChangeEmitter {
        void emit_nfc_state_change(String state);
    }

    private static final String TAG = "NfcModule";

    public static final int NFC_STATE_VALUE_UNKNOWN = 0;
    public static final int NFC_STATE_VALUE_OFF = 1;
    public static final int NFC_STATE_VALUE_TURNING_ON = 2;
    public static final int NFC_STATE_VALUE_ON = 3;
    public static final int NFC_STATE_VALUE_TURNING_OFF = 4;

    public static final String NFC_STATE_UNKNOWN = "unknown";
    public static final String NFC_STATE_OFF = "powered_off";
    public static final String NFC_STATE_TURNING_ON = "powering_on";
    public static final String NFC_STATE_ON = "powered_on";
    public static final String NFC_STATE_TURNING_OFF = "powering_off";

    private final DiagnosticPlugin plugin;
    private final Context application_context;
    private final NfcStateChangeEmitter emitter;

    private NfcManager nfc_manager;
    private String current_nfc_state = NFC_STATE_UNKNOWN;
    private boolean receiver_registered = false;

    public NfcModule(DiagnosticPlugin plugin, NfcStateChangeEmitter emitter) {
        this.plugin = plugin;
        this.application_context = plugin.getContext().getApplicationContext();
        this.emitter = emitter;

        try {
            this.nfc_manager = (NfcManager) application_context.getSystemService(Context.NFC_SERVICE);
        } catch (Exception e) {
            Log.w(TAG, "Unable to obtain NfcManager: " + e.getMessage());
        }

        register_receiver();
        initialize_current_state();
    }

    private void register_receiver() {
        if (receiver_registered) {
            return;
        }

        try {
            IntentFilter filter = new IntentFilter(NfcAdapter.ACTION_ADAPTER_STATE_CHANGED);
            application_context.registerReceiver(nfc_state_changed_receiver, filter);
            receiver_registered = true;
        } catch (Exception e) {
            Log.w(TAG, "Unable to register NFC state change receiver: " + e.getMessage());
        }
    }

    public void destroy() {
        if (!receiver_registered) {
            return;
        }

        try {
            application_context.unregisterReceiver(nfc_state_changed_receiver);
            receiver_registered = false;
        } catch (Exception e) {
            Log.w(TAG, "Unable to unregister NFC state change receiver: " + e.getMessage());
        }
    }

    private void initialize_current_state() {
        try {
            current_nfc_state = is_nfc_available_internal() ? NFC_STATE_ON : NFC_STATE_OFF;
        } catch (Exception e) {
            Log.w(TAG, "Unable to get initial NFC state: " + e.getMessage());
            current_nfc_state = NFC_STATE_UNKNOWN;
        }
    }

    public void switch_to_nfc_settings(PluginCall call) {
        try {
            Intent settings_intent;

            if (Build.VERSION.SDK_INT >= 16) {
                settings_intent = new Intent(Settings.ACTION_NFC_SETTINGS);
            } else {
                settings_intent = new Intent(Settings.ACTION_WIRELESS_SETTINGS);
            }

            plugin.getActivity().startActivity(settings_intent);
            call.resolve();
        } catch (Exception e) {
            call.reject("Failed to open NFC settings: " + e.getMessage());
        }
    }

    public void is_nfc_present(PluginCall call) {
        JSObject result = new JSObject();
        result.put("present", is_nfc_present_internal());
        call.resolve(result);
    }

    public void is_nfc_enabled(PluginCall call) {
        JSObject result = new JSObject();
        result.put("enabled", is_nfc_enabled_internal());
        call.resolve(result);
    }

    public void is_nfc_available(PluginCall call) {
        JSObject result = new JSObject();
        result.put("available", is_nfc_available_internal());
        call.resolve(result);
    }

    private boolean is_nfc_present_internal() {
        try {
            NfcAdapter adapter = get_adapter();
            return adapter != null;
        } catch (Exception e) {
            Log.e(TAG, "Error checking NFC presence: " + e.getMessage());
            return false;
        }
    }

    private boolean is_nfc_enabled_internal() {
        try {
            NfcAdapter adapter = get_adapter();
            return adapter != null && adapter.isEnabled();
        } catch (Exception e) {
            Log.e(TAG, "Error checking NFC enabled state: " + e.getMessage());
            return false;
        }
    }

    private boolean is_nfc_available_internal() {
        return is_nfc_present_internal() && is_nfc_enabled_internal();
    }

    private NfcAdapter get_adapter() {
        if (nfc_manager == null) {
            return null;
        }
        return nfc_manager.getDefaultAdapter();
    }

    private void notify_nfc_state_change(int state_value) {
        String new_state = get_nfc_state(state_value);

        if (!new_state.equals(current_nfc_state)) {
            current_nfc_state = new_state;
            emitter.emit_nfc_state_change(new_state);
        }
    }

    private String get_nfc_state(int state_value) {
        switch (state_value) {
            case NFC_STATE_VALUE_OFF:
                return NFC_STATE_OFF;
            case NFC_STATE_VALUE_TURNING_ON:
                return NFC_STATE_TURNING_ON;
            case NFC_STATE_VALUE_ON:
                return NFC_STATE_ON;
            case NFC_STATE_VALUE_TURNING_OFF:
                return NFC_STATE_TURNING_OFF;
            default:
                return NFC_STATE_UNKNOWN;
        }
    }

    private final BroadcastReceiver nfc_state_changed_receiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            try {
                if (intent == null || !NfcAdapter.ACTION_ADAPTER_STATE_CHANGED.equals(intent.getAction())) {
                    return;
                }

                int state_value = intent.getIntExtra(NfcAdapter.EXTRA_ADAPTER_STATE, -1);
                notify_nfc_state_change(state_value);
            } catch (Exception e) {
                Log.e(TAG, "Error receiving NFC state change: " + e.getMessage());
            }
        }
    };
}
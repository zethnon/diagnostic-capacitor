package com.noesis.diagnostic;

import com.getcapacitor.Logger;

public class DiagnosticPlugin {

    public String echo(String value) {
        Logger.info("Echo", value);
        return value;
    }
}

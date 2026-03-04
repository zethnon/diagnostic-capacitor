import XCTest

final class DiagnosticSmokeTests: XCTestCase {

    func testDiagnosticPluginBridge() {
        let app = XCUIApplication()
        app.launch()

        // We set document.title to DIAG_OK:* or DIAG_FAIL:*.
        // On many setups this shows up as a static text/accessibility label.
        let ok = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "DIAG_OK:")).firstMatch
        let fail = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "DIAG_FAIL:")).firstMatch

        XCTAssertTrue(ok.waitForExistence(timeout: 25) || fail.waitForExistence(timeout: 25))
        XCTAssertFalse(fail.exists, "Plugin call failed (DIAG_FAIL present)")
    }
}
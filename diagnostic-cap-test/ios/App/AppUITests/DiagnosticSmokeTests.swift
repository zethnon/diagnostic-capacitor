import XCTest

final class DiagnosticSmokeTests: XCTestCase {

    func testDiagnosticPluginBridge() {
        let app = XCUIApplication()
        app.launch()

        // Wait until the web UI renders either DIAG_OK or DIAG_FAIL
        let diagOk = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "DIAG_OK")).firstMatch
        let diagFail = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "DIAG_FAIL")).firstMatch

        let okExists = diagOk.waitForExistence(timeout: 60)
        let failExists = diagFail.waitForExistence(timeout: 60)

        // Dump whatever we got to the build logs (so we can actually debug)
        if okExists {
            print("✅ DIAG RESULT: \(diagOk.label)")
        }
        if failExists {
            print("❌ DIAG RESULT: \(diagFail.label)")
        }

        // If fail exists -> hard fail with the actual message
        XCTAssertFalse(failExists, "Plugin call failed: \(diagFail.exists ? diagFail.label : "DIAG_FAIL present but label missing")")

        // If neither appears -> also fail (web didn't load / marker not rendered)
        XCTAssertTrue(okExists || failExists, "Neither DIAG_OK nor DIAG_FAIL appeared within timeout (web UI not ready)")
    }
}
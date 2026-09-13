import XCTest
final class FlowTests: XCTestCase {
    @MainActor
    func testChoosePlayResultRetryNextAndDurableHistory() throws {
        let app=XCUIApplication(); app.launch()
        reveal(app.buttons["challenge-0"],in:app)
        app.buttons["challenge-0"].tap()
        XCTAssertTrue(app.buttons["start"].waitForExistence(timeout:3))
        attachment(app,"preparation")
        reveal(app.buttons["start"],in:app)
        app.buttons["start"].tap()
        XCTAssertTrue(app.buttons["endAttempt"].waitForExistence(timeout:5))
        attachment(app,"playing")
        let originalSurface=app.otherElements["playSurface"].frame
        XCTAssertTrue(app.staticTexts["Carry the silence."].waitForExistence(timeout:12))
        attachment(app,"silence")
        XCTAssertEqual(app.otherElements["playSurface"].frame,originalSurface)
        XCTAssertFalse(app.staticTexts["BPM"].exists)
        // Real audio runs to completion. No injected taps are represented as human play.
        XCTAssertTrue(app.buttons["retry"].waitForExistence(timeout:40))
        XCTAssertTrue(app.staticTexts["resultTitle"].exists)
        attachment(app,"result-no-input")
        reveal(app.buttons["retry"],in:app)
        app.buttons["retry"].tap(); XCTAssertTrue(app.buttons["start"].exists)
        reveal(app.buttons["start"],in:app)
        app.buttons["start"].tap(); app.buttons["endAttempt"].tap()
        reveal(app.buttons["next"],in:app)
        app.buttons["next"].tap(); XCTAssertTrue(app.staticTexts["Stay a little"].exists)
        app.buttons["home"].tap(); app.swipeUp()
        reveal(app.buttons["history"],in:app)
        XCTAssertTrue(app.buttons["history"].waitForExistence(timeout:3))
        app.terminate(); app.launch(); app.swipeUp()
        reveal(app.buttons["history"],in:app)
        XCTAssertTrue(app.buttons["history"].waitForExistence(timeout:3))
    }
    @MainActor
    func testLargeTextNavigationAndAccessibilityAudit() throws {
        let app=XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        attachment(app,"selection-large-text")
        reveal(app.buttons["challenge-0"],in:app)
        reveal(app.buttons["challenge-0"],in:app)
        app.buttons["challenge-0"].tap()
        reveal(app.buttons["start"],in:app)
        XCTAssertTrue(app.buttons["start"].isHittable)
        attachment(app,"preparation-large-text")
        try app.performAccessibilityAudit(for:[.contrast,.elementDetection,.hitRegion,.sufficientElementDescription,.trait,.textClipped])
        reveal(app.buttons["start"],in:app)
        app.buttons["start"].tap()
        XCTAssertTrue(app.buttons["endAttempt"].waitForExistence(timeout:4))
        XCTAssertTrue(app.buttons["endAttempt"].isHittable)
        attachment(app,"playing-large-text")
        app.buttons["endAttempt"].tap()
        reveal(app.buttons["retry"],in:app)
        XCTAssertTrue(app.buttons["retry"].isHittable)
        app.buttons["retry"].tap()
        XCTAssertTrue(app.buttons["home"].isHittable)
    }
    @MainActor
    func testStrumSurfaceAcceptsRepeatedDownwardGestures() throws {
        let app=XCUIApplication(); app.launch()
        app.segmentedControls["modePicker"].buttons["Strum"].tap()
        reveal(app.buttons["challenge-0"],in:app)
        app.buttons["challenge-0"].tap()
        reveal(app.buttons["start"],in:app)
        app.buttons["start"].tap()
        let surface=app.otherElements["playSurface"]
        XCTAssertTrue(surface.waitForExistence(timeout:3))
        let start=surface.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.25))
        let end=surface.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.75))
        for _ in 0..<4 { start.press(forDuration:0.01,thenDragTo:end,withVelocity:.fast,thenHoldForDuration:0) }
        XCTAssertTrue(app.buttons["endAttempt"].exists)
        attachment(app,"strum-active")
        app.buttons["endAttempt"].tap()
        XCTAssertTrue(app.buttons["retry"].waitForExistence(timeout:3))
    }

    @MainActor
    func testCompleteTrainingJourneyWithIsolatedSoftwareInputsAndClock() throws {
        #if targetEnvironment(simulator)
        let app=XCUIApplication()
        app.launchArguments=["-phase3-ui-fixture"]
        app.launchEnvironment["TAPHAP_UI_FIXTURE_ID"]=UUID().uuidString
        app.launch()
        func begin() { reveal(app.buttons["training"],in:app); XCTAssertTrue(app.buttons["training"].isEnabled); app.buttons["training"].tap(); XCTAssertTrue(app.buttons["start"].waitForExistence(timeout:3),app.debugDescription) }
        func step() {
            reveal(app.buttons["start"],in:app); app.buttons["start"].tap()
            XCTAssertTrue(app.staticTexts["trainingSummary"].waitForExistence(timeout:3))
            if app.staticTexts["trainingSummary"].label.contains("Compared with") {
                XCTAssertTrue(app.staticTexts["trainingSummary"].label.contains("60.0 ms lower"))
                attachment(app,"checkpoint-comparison-software-fixture")
            }
            reveal(app.buttons["continueTraining"],in:app); app.buttons["continueTraining"].tap()
        }
        begin(); step()
        // Process exit between trials: resume the second saved step from disk.
        app.terminate(); app.launch(); begin()
        XCTAssertTrue(app.staticTexts["Baseline · step 2 of 3"].exists)
        step(); step()
        attachment(app,"training-baseline-complete")
        for _ in 0..<3 {
            reveal(app.buttons["advanceFixtureDay"],in:app); app.buttons["advanceFixtureDay"].tap()
            begin(); for _ in 0..<4 { step() }
        }
        reveal(app.buttons["training"],in:app); XCTAssertFalse(app.buttons["training"].isEnabled)
        reveal(app.buttons["advanceFixtureDay"],in:app); app.buttons["advanceFixtureDay"].tap()
        begin(); for _ in 0..<3 { step() }
        attachment(app,"training-checkpoint-complete")
        begin(); XCTAssertTrue(app.staticTexts["Paper Kite · Transfer"].exists)
        for _ in 0..<3 { step() }
        reveal(app.buttons["trainingHistory"],in:app); app.buttons["trainingHistory"].tap()
        attachment(app,"training-transfer-complete")
        let baseline=app.staticTexts.matching(NSPredicate(format:"label BEGINSWITH %@","Three-trial baseline saved:")).firstMatch
        reveal(baseline,in:app); XCTAssertTrue(baseline.isHittable)
        attachment(app,"training-history-oldest-reference")
        app.terminate()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        reveal(app.buttons["trainingHistory"],in:app); app.buttons["trainingHistory"].tap()
        reveal(baseline,in:app); XCTAssertTrue(baseline.isHittable)
        attachment(app,"training-history-largest-text")
        #else
        throw XCTSkip("Software journey fixtures are simulator-only; never create them in phone history.")
        #endif
    }

    @MainActor
    private func reveal(_ element: XCUIElement,in app: XCUIApplication) {
        for _ in 0..<30 {
            if element.exists {
                let f=element.frame, bounds=app.frame
                if element.isHittable && f.midY > bounds.minY+120 && f.midY < bounds.maxY-80 { return }
                if f.midY <= bounds.minY+120 { app.swipeDown(); continue }
            }
            app.swipeUp()
        }
    }
    @MainActor
    private func attachment(_ app: XCUIApplication,_ name: String) {
        let attachment=XCTAttachment(screenshot:app.screenshot()); attachment.name=name; attachment.lifetime = .keepAlways; add(attachment)
    }
}

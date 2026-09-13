import XCTest
final class FlowTests: XCTestCase {
    @MainActor
    func testChoosePlayResultRetryNextAndDurableHistory() throws {
        let app=XCUIApplication(); app.launch()
        app.buttons["challenge-0"].tap()
        XCTAssertTrue(app.buttons["start"].waitForExistence(timeout:3))
        attachment(app,"preparation")
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
        app.buttons["retry"].tap(); XCTAssertTrue(app.buttons["start"].exists)
        app.buttons["start"].tap(); app.buttons["endAttempt"].tap()
        app.buttons["next"].tap(); XCTAssertTrue(app.staticTexts["Stay a little"].exists)
        app.buttons["home"].tap(); app.swipeUp()
        XCTAssertTrue(app.buttons["history"].waitForExistence(timeout:3))
        app.terminate(); app.launch(); app.swipeUp()
        XCTAssertTrue(app.buttons["history"].waitForExistence(timeout:3))
    }
    @MainActor
    func testLargeTextNavigationAndAccessibilityAudit() throws {
        let app=XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        attachment(app,"selection-large-text")
        reveal(app.buttons["challenge-0"],in:app)
        app.buttons["challenge-0"].tap()
        reveal(app.buttons["start"],in:app)
        XCTAssertTrue(app.buttons["start"].isHittable)
        attachment(app,"preparation-large-text")
        try app.performAccessibilityAudit(for:[.contrast,.elementDetection,.hitRegion,.sufficientElementDescription,.trait,.textClipped])
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
        app.buttons["challenge-0"].tap()
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
    private func reveal(_ element: XCUIElement,in app: XCUIApplication) {
        for _ in 0..<10 { if element.isHittable { return }; app.swipeUp() }
    }
    @MainActor
    private func attachment(_ app: XCUIApplication,_ name: String) {
        let attachment=XCTAttachment(screenshot:app.screenshot()); attachment.name=name; attachment.lifetime = .keepAlways; add(attachment)
    }
}

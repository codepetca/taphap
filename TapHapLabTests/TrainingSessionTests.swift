import XCTest
@testable import TapHapLab

final class TrainingSessionTests: XCTestCase {
    func testSessionRequiresStableCalibrationBeforeGap() throws {
        var session = TrainingSession()
        session.begin()

        XCTAssertNil(session.prepareGap(now: 3))

        for tap in (0..<12).map({ Double($0) * 0.5 }) {
            session.recordTap(at: tap)
        }

        let plan = try XCTUnwrap(session.prepareGap(now: 6))
        XCTAssertEqual(session.phase, .warning)
        XCTAssertGreaterThan(plan.startTime, 6)
        XCTAssertEqual(plan.duration, 4, accuracy: 0.001)
    }

    func testSessionScoresOnlySilentGapTaps() throws {
        var session = TrainingSession()
        session.begin()
        for tap in (0..<12).map({ 1.0 + Double($0) * 0.5 }) {
            session.recordTap(at: tap)
        }
        let plan = try XCTUnwrap(session.prepareGap(now: 7))

        session.recordTap(at: plan.startTime - 0.5)
        session.beginGap()
        for tap in stride(from: plan.startTime, through: plan.endTime, by: plan.pulse.period) {
            session.recordTap(at: tap)
        }

        let score = try XCTUnwrap(session.finishGap())
        XCTAssertEqual(session.hiddenTaps.count, 9)
        XCTAssertEqual(score.endDriftMilliseconds, 0, accuracy: 0.001)
        XCTAssertEqual(session.phase, .result)
    }
}

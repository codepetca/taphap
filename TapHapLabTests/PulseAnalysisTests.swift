import XCTest
@testable import TapHapLab

final class PulseAnalysisTests: XCTestCase {
    func testFitsExact120BPMPulse() throws {
        let taps = (0..<12).map { 10.0 + Double($0) * 0.5 }
        let estimate = try XCTUnwrap(PulseEstimator.fit(timestamps: taps))

        XCTAssertEqual(estimate.bpm, 120, accuracy: 0.001)
        XCTAssertEqual(estimate.anchor, 10, accuracy: 0.001)
        XCTAssertEqual(estimate.residualJitter, 0, accuracy: 0.001)
        XCTAssertEqual(estimate.acceptedTapCount, 12)
    }

    func testRejectsOneLargeTimingOutlier() throws {
        var taps = (0..<14).map { 20.0 + Double($0) * 0.5 }
        taps[6] += 0.18

        let estimate = try XCTUnwrap(PulseEstimator.fit(timestamps: taps))

        XCTAssertEqual(estimate.bpm, 120, accuracy: 0.2)
        XCTAssertLessThan(estimate.acceptedTapCount, taps.count)
        XCTAssertLessThan(estimate.residualJitter, 0.01)
    }

    func testKnownGridReportsStableRouteOffsetSeparatelyFromJitter() throws {
        let taps = (0..<10).map { 5.0 + Double($0) * 0.5 + 0.042 }
        let diagnostics = try XCTUnwrap(
            KnownGridDiagnostics.measure(timestamps: taps, anchor: 5, period: 0.5)
        )

        XCTAssertEqual(diagnostics.meanOffsetMilliseconds, 42, accuracy: 0.001)
        XCTAssertEqual(diagnostics.jitterMilliseconds, 0, accuracy: 0.001)
    }

    func testGapScoreDetectsAcceleration() throws {
        let pulse = PulseEstimate(
            period: 0.5,
            anchor: 10,
            residualJitter: 0,
            confidence: 1,
            acceptedTapCount: 12,
            totalTapCount: 12
        )
        let plan = GapPlan(startTime: 14, endTime: 18, beatCount: 8, pulse: pulse)
        let taps = (0...8).map { index in
            let progress = Double(index) / 8
            return 14 + Double(index) * 0.5 - 0.040 * progress
        }

        let score = try XCTUnwrap(GapScorer.score(timestamps: taps, plan: plan))

        XCTAssertEqual(score.endDriftMilliseconds, -40, accuracy: 0.001)
        XCTAssertEqual(score.tempoSlopeMillisecondsPerSecond, -10, accuracy: 0.001)
        XCTAssertEqual(score.direction, "speeding up")
        XCTAssertEqual(score.scoredTapCount, 9)
    }

    func testGapScoreIgnoresDuplicateTapOnSameBeat() throws {
        let pulse = PulseEstimate(
            period: 0.5,
            anchor: 0,
            residualJitter: 0,
            confidence: 1,
            acceptedTapCount: 12,
            totalTapCount: 12
        )
        let plan = GapPlan(startTime: 2, endTime: 4, beatCount: 4, pulse: pulse)
        let score = try XCTUnwrap(
            GapScorer.score(timestamps: [2.01, 2.20, 2.49, 3.01, 3.50, 4.01], plan: plan)
        )

        XCTAssertEqual(score.scoredTapCount, 5)
        XCTAssertLessThan(score.meanAbsoluteErrorMilliseconds, 12)
    }
}

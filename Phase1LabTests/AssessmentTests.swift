import XCTest
#if SWIFT_PACKAGE
@testable import Phase1Core
#else
@testable import TapHapPhase1
#endif

final class AssessmentTests: XCTestCase {
    var bundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for:Self.self)
        #endif
    }
    func map() throws -> BeatMap {
        let folder = bundle.url(forResource:"Fixtures",withExtension:nil)!
        return try JSONDecoder().decode(BeatMap.self,from:Data(contentsOf:folder.appendingPathComponent("beat-map.json")))
    }
    func replay(_ name: String) throws -> [InputEvent] {
        struct Recording: Decodable { let events: [InputEvent] }
        let folder = bundle.url(forResource:"AssessmentFixtures",withExtension:nil)!
        return try JSONDecoder().decode(Recording.self,from:Data(contentsOf:folder.appendingPathComponent(name+".json"))).events
    }
    func events(offset: (Int) -> Double = { _ in 0.042 }) -> [InputEvent] {
        (0..<64).map { i in
            let t = 1+Double(i)*0.5+offset(i)
            return InputEvent(trackSeconds:t,hostSeconds:1000+t,observedHostSeconds:1000+t+0.01,mode:.tap)
        }
    }
    func testCapturedTapReplaysKeepSlowdownWithoutInventingLanding() throws {
        for name in ["captured-tap-a","captured-tap-b"] {
            let events = try replay(name), map = try map()
            let result = Assessor.assess(events:events,map:map)
            XCTAssertEqual(result.kind,.partial); XCTAssertEqual(result.scoreIssue,.ambiguousInput)
            XCTAssertNil(result.score); XCTAssertNil(result.invalidation)
            let base = try XCTUnwrap(result.baseline), gap = try XCTUnwrap(result.observedIntervals)
            XCTAssertEqual(base.inputCount,12); XCTAssertLessThan(base.residualRMSMS,14)
            XCTAssertGreaterThan(gap.medianSpacingMS,550); XCTAssertLessThan(gap.medianSpacingMS,565)
            XCTAssertFalse(gap.hasIrregularIntervals)
            XCTAssertTrue(result.summary.contains("farther apart")); XCTAssertTrue(result.summary.contains("Landing unavailable"))
            for _ in 0..<10 { XCTAssertEqual(Assessor.assess(events:events,map:map),result) }
            print("ASSESSMENT \(name): \(String(data:try JSONEncoder().encode(result),encoding:.utf8)!)")
        }
    }
    func testCapturedStrumKeepsMissingStrokeUncertainty() throws {
        let result = Assessor.assess(events:try replay("captured-strum"),map:try map())
        XCTAssertEqual(result.kind,.partial); XCTAssertNil(result.score)
        let gap = try XCTUnwrap(result.observedIntervals)
        XCTAssertEqual(gap.longIntervalCount,1); XCTAssertEqual(gap.shortIntervalCount,0)
        XCTAssertEqual(gap.largestIntervalMS,1070.581,accuracy:0.002)
        XCTAssertTrue(result.summary.contains("missed or extra input is possible"))
        XCTAssertFalse(result.summary.contains("farther apart")) // do not call a missing stroke a tempo measurement
        print("ASSESSMENT captured-strum: \(String(data:try JSONEncoder().encode(result),encoding:.utf8)!)")
    }
    func testPhaseWrapsStayPartialInBothDirections() throws {
        for direction in [-1.0,1.0] {
            let input = events { i in 0.042 + direction*0.03*Double(max(0,min(18,i-16))) }
            let result = Assessor.assess(events:input,map:try map())
            XCTAssertEqual(result.kind,.partial); XCTAssertNil(result.score)
            XCTAssertEqual(result.scoreIssue,.ambiguousInput)
            XCTAssertNotNil(result.baseline); XCTAssertFalse(try XCTUnwrap(result.observedIntervals).hasIrregularIntervals)
        }
    }
    func testMissingAndDuplicateInputsNeverGainAssumedBeatIdentities() throws {
        var missing = events(); missing.remove(at:22)
        var duplicate = events(); let t = duplicate[22].trackSeconds+0.04
        duplicate.insert(InputEvent(trackSeconds:t,hostSeconds:1000+t,observedHostSeconds:1000+t+0.01,mode:.tap),at:23)
        for (input,issue,longCount,shortCount) in [(missing,TrialError.missingInput,1,0),(duplicate,.duplicateInput,0,1)] {
            let result = Assessor.assess(events:input,map:try map())
            XCTAssertEqual(result.kind,.partial); XCTAssertEqual(result.scoreIssue,issue); XCTAssertNil(result.score)
            XCTAssertEqual(result.observedIntervals?.longIntervalCount,longCount)
            XCTAssertEqual(result.observedIntervals?.shortIntervalCount,shortCount)
            XCTAssertTrue(result.summary.contains("missed or extra input is possible"))
        }
    }
    func testCaptureAndLifecycleInvalidationsSuppressEveryTimingClaim() throws {
        let input = try replay("captured-tap-a"), map = try map()
        for issue: TrialError in [.routeChanged,.interruption,.backgrounded,.cancelled,.multipleTouches,.invalidClock,.staleClock,.discontinuity,.ambiguousInput] {
            let result = Assessor.assess(events:input,map:map,invalidations:[issue])
            XCTAssertEqual(result.kind,.invalid); XCTAssertEqual(result.invalidation,issue)
            XCTAssertNil(result.scoreIssue); XCTAssertNil(result.baseline); XCTAssertNil(result.observedIntervals); XCTAssertNil(result.score)
        }
        var invalid = input
        let original = invalid[20]
        invalid[20] = InputEvent(trackSeconds:original.trackSeconds,hostSeconds:original.hostSeconds,observedHostSeconds:original.hostSeconds+1,mode:.tap)
        XCTAssertEqual(Assessor.assess(events:invalid,map:map).kind,.invalid)
    }
    func testPartialFeedbackRequiresReliableAudibleBaseline() throws {
        var missingOpening = try replay("captured-tap-a"); missingOpening.remove(at:8)
        let missing = Assessor.assess(events:missingOpening,map:try map())
        XCTAssertEqual(missing.kind,.invalid); XCTAssertNil(missing.baseline); XCTAssertNil(missing.observedIntervals)
        let unstable = events { i in 0.042 + (i>=4 && i<16 ? (i.isMultiple(of:2) ? 0.075 : -0.075) : 0) }
        XCTAssertEqual(Assessor.assess(events:unstable,map:try map()).invalidation,.unstableBaseline)
    }
    func testTooFewSilentInputsDoNotProduceCadenceStatistics() throws {
        let input = events().filter { $0.trackSeconds < 9.1 || $0.trackSeconds >= 17 || $0.trackSeconds < 11 }
        let result = Assessor.assess(events:input,map:try map())
        XCTAssertEqual(result.kind,.partial); XCTAssertNotNil(result.baseline); XCTAssertNil(result.observedIntervals)
        XCTAssertTrue(result.summary.contains("Too few silent inputs"))
    }
    func testValidFullScoreIsUnchangedAndAssessmentRoundTrips() throws {
        let input = events(), map = try map()
        let score = try Scorer.score(events:input,map:map)
        let result = Assessor.assess(events:input,map:map)
        XCTAssertEqual(result.kind,.scored); XCTAssertEqual(result.score,score)
        XCTAssertNil(result.scoreIssue); XCTAssertNil(result.invalidation)
        for value in [result,Assessor.assess(events:try replay("captured-tap-a"),map:map),TrialAssessment.invalid(.staleClock)] {
            XCTAssertEqual(try JSONDecoder().decode(TrialAssessment.self,from:JSONEncoder().encode(value)),value)
        }
    }
}

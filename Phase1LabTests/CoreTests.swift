import XCTest
#if SWIFT_PACKAGE
@testable import Phase1Core
#else
@testable import TapHapPhase1
#endif

final class CoreTests: XCTestCase {
    var fixtures: URL {
        #if SWIFT_PACKAGE
        return Bundle.module.url(forResource: "Fixtures", withExtension: nil)!
        #else
        return Bundle(for: Self.self).url(forResource: "Fixtures", withExtension: nil)!
        #endif
    }
    func map() throws -> BeatMap { try JSONDecoder().decode(BeatMap.self, from: Data(contentsOf: fixtures.appendingPathComponent("beat-map.json"))) }
    struct Fixture: Decodable { let name: String; let mode: String; let expected: String; let invalidations: [TrialError]; let events: [InputEvent] }
    func testRecordedFixturesAreDeterministicAndDiagnoseBothModes() throws {
        let urls = try FileManager.default.contentsOfDirectory(at: fixtures, includingPropertiesForKeys: nil).filter { $0.lastPathComponent != "beat-map.json" && $0.pathExtension == "json" }.sorted { $0.path < $1.path }
        XCTAssertEqual(urls.count,22)
        for url in urls {
            let fixture = try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
            do {
                let score = try Scorer.score(events: fixture.events, map: map(), invalidations: fixture.invalidations)
                XCTAssertEqual(score.diagnosis,fixture.expected,url.lastPathComponent)
                for _ in 0..<10 { XCTAssertEqual(try Scorer.score(events: fixture.events, map: map(), invalidations: fixture.invalidations),score) }
                XCTAssertEqual(score.baselinePhaseMS,42,accuracy:0.0001)
                if fixture.name == "steady" { XCTAssertEqual(score.reentryMS,0,accuracy:0.0001); XCTAssertEqual(score.consistencyMS,0,accuracy:0.0001) }
                if fixture.name == "accelerated" { XCTAssertLessThan(score.reentryMS,-100); XCTAssertLessThan(score.accelerationMSPerBeatSquared,-0.8) }
                if fixture.name == "decelerated" { XCTAssertGreaterThan(score.reentryMS,100); XCTAssertGreaterThan(score.accelerationMSPerBeatSquared,0.8) }
                if fixture.name == "shifted" { XCTAssertEqual(score.reentryMS,90,accuracy:0.0001); XCTAssertEqual(score.tempoDriftMSPerBeat,0,accuracy:0.0001) }
                print("FIXTURE \(fixture.mode)/\(fixture.name): \(String(data: try JSONEncoder().encode(score), encoding: .utf8)!)")
            } catch let error as TrialError { XCTAssertEqual(error.rawValue,fixture.expected,url.lastPathComponent); print("FIXTURE \(fixture.mode)/\(fixture.name): invalid \(error.rawValue)") }
        }
    }
    func testMapValidationAndVariableTempoConversion() throws {
        let original = try Data(contentsOf: fixtures.appendingPathComponent("beat-map.json"))
        var json = try JSONSerialization.jsonObject(with: original) as! [String: Any]
        for key in ["sampleRate","frameCount","fadeFrames","returnBeat","gapStartBeat","baselineStartBeat"] {
            var bad = json; bad[key] = -1
            XCTAssertThrowsError(try JSONDecoder().decode(BeatMap.self,from: JSONSerialization.data(withJSONObject: bad)).validate(),key)
        }
        var beats = json["beats"] as! [Int]; beats[25] = beats[24]
        var bad = json; bad["beats"] = beats
        XCTAssertThrowsError(try JSONDecoder().decode(BeatMap.self,from: JSONSerialization.data(withJSONObject: bad)).validate())
        beats[25] += 12000; json["beats"] = beats
        let variable = try JSONDecoder().decode(BeatMap.self,from: JSONSerialization.data(withJSONObject: json))
        try variable.validate(); XCTAssertEqual(variable.seconds(25),13.25); XCTAssertEqual(variable.nearestBeat(to:13.26),25)
    }
    func testEnvelopeExactBoundariesAndArbitraryRenderPartitions() throws {
        let map = try map(), e = try GapEnvelope(map: map)
        XCTAssertEqual(e.gain(at:e.fadeStart),1)
        XCTAssertEqual(e.gain(at:e.fadeStart+2400),0.5,accuracy:0.00001)
        XCTAssertEqual(e.gain(at:e.silentStart),0); XCTAssertEqual(e.gain(at:e.returnStart),0)
        XCTAssertEqual(e.gain(at:e.fullReturn),1)
        for sample in e.silentStart..<e.returnStart { XCTAssertEqual(e.gain(at:sample),0) }
        let expected = (0..<map.frameCount).map { e.gain(at:$0) }
        for size: Int64 in [127,512,4096] {
            var cursor: Int64 = 0
            while cursor < map.frameCount {
                let end = min(map.frameCount,cursor+size)
                for frame in cursor..<end { XCTAssertEqual(e.gain(at:frame),expected[Int(frame)]) }
                cursor = end
            }
            XCTAssertEqual(cursor,map.frameCount)
        }
    }
    func testClockConversionRejectsUIWallTimeAndDiscontinuities() throws {
        let anchor = AudioAnchor(hostSeconds:100,sample:48000,sampleRate:48000)
        XCTAssertEqual(try anchor.trackSeconds(touchHostSeconds:100.01,observedHostSeconds:100.02),1.01,accuracy:1e-9)
        XCTAssertThrowsError(try anchor.trackSeconds(touchHostSeconds:1_700_000_000,observedHostSeconds:100.02))
        XCTAssertThrowsError(try anchor.trackSeconds(touchHostSeconds:100.01,observedHostSeconds:100.3))
        XCTAssertThrowsError(try anchor.trackSeconds(touchHostSeconds:.nan,observedHostSeconds:100.02))
        try AudioAnchor(hostSeconds:100.1,sample:52800,sampleRate:48000).validateContinuation(from:anchor)
        XCTAssertThrowsError(try AudioAnchor(hostSeconds:100.1,sample:53000,sampleRate:48000).validateContinuation(from:anchor))
        XCTAssertThrowsError(try AudioAnchor(hostSeconds:99,sample:48001,sampleRate:48000).validateContinuation(from:anchor))
    }
    func testCrossingsInterpolateAndDebounceWithoutGestureCompletion() throws {
        var tracker = StrumTracker()
        tracker.begin(TouchPoint(y:20,hostSeconds:10))
        let down = try XCTUnwrap(tracker.move(TouchPoint(y:80,hostSeconds:10.02),referenceY:50))
        XCTAssertEqual(down.hostSeconds,10.01,accuracy:1e-9); XCTAssertEqual(down.direction,.down)
        XCTAssertNil(try tracker.move(TouchPoint(y:20,hostSeconds:10.03),referenceY:50))
        tracker.cancel(); tracker.begin(TouchPoint(y:80,hostSeconds:11))
        XCTAssertEqual(try tracker.move(TouchPoint(y:20,hostSeconds:11.02),referenceY:50)?.direction,.up)
        tracker.begin(TouchPoint(y:20,hostSeconds:12))
        XCTAssertThrowsError(try tracker.move(TouchPoint(y:80,hostSeconds:12.1),referenceY:50))
        tracker.begin(TouchPoint(y:50,hostSeconds:13))
        XCTAssertNil(try tracker.move(TouchPoint(y:80,hostSeconds:13.01),referenceY:50))
    }
    func testAllEnvironmentalInvalidationsPreemptScores() throws {
        for reason: TrialError in [.routeChanged,.interruption,.backgrounded,.cancelled,.multipleTouches,.discontinuity] {
            XCTAssertThrowsError(try Scorer.score(events: [],map:map(),invalidations:[reason])) { XCTAssertEqual($0 as? TrialError,reason) }
        }
    }
}

import Foundation
import XCTest
#if SWIFT_PACKAGE
@testable import GameCore
import Phase1Core
#else
@testable import TapHapGame
#endif
final class GameTests: XCTestCase {
    func catalog() throws -> SongCatalog {
        #if SWIFT_PACKAGE
        let bundle=Bundle.module
        #else
        let bundle=Bundle(for:Self.self)
        #endif
        return try JSONDecoder().decode(SongCatalog.self,from:Data(contentsOf:bundle.url(forResource:"catalog",withExtension:"json",subdirectory:"Fixtures")!))
    }
    func key(challenge: String="first-light", mode: InputMode = .tap, route: String="Speaker", assistance: String="direct-touch", content: String="v1", device: String="phone", system: String="26.6", rate: Double=48000, latency: Double=0.015) -> ComparisonKey {
        ComparisonKey(content:content,challenge:challenge,mode:mode,device:device,system:system,route:route,sampleRate:rate,bufferDuration:0.005,outputLatency:latency,assistance:assistance)
    }
    func events(_ map: BeatMap, mode: InputMode = .tap, landing: Double=0) -> [InputEvent] {
        map.beats.indices.map { i in
            let t=map.seconds(i)+0.04+(i >= map.gapStartBeat ? landing : 0)
            return InputEvent(trackSeconds:t,hostSeconds:100+t,observedHostSeconds:100+t+0.005,mode:mode,direction:mode == .strum ? .down : nil)
        }
    }
    func testAllChallengesHaveDeterministicScoresAndZeroGainGaps() throws {
        let catalog=try catalog(); try catalog.validate()
        XCTAssertEqual(catalog.challenges.map(\.gapSeconds),[4,6,8])
        for challenge in catalog.challenges {
            let map=challenge.map, envelope=try GapEnvelope(map:map)
            XCTAssertEqual(envelope.gain(at:envelope.silentStart),0)
            XCTAssertEqual(envelope.gain(at:envelope.returnStart-1),0)
            XCTAssertEqual(envelope.gain(at:envelope.fullReturn),1)
            for mode in [InputMode.tap,.strum] {
                let captured=events(map,mode:mode)
                let expected=Assessor.assess(events:captured,map:map)
                XCTAssertEqual(expected.kind,.scored)
                XCTAssertEqual(expected.score?.reentryMS ?? 1,0,accuracy:0.000001)
                for _ in 0..<5 { XCTAssertEqual(Assessor.assess(events:captured,map:map),expected) }
            }
        }
    }
    func testStateBoundariesAndCancelledStartupCannotArm() throws {
        let map=try catalog().challenges[0].map
        var session=ChallengeSession()
        let old=session.prepare(); session.finish(reason:.backgrounded)
        XCTAssertFalse(session.arm(generation:old)); XCTAssertEqual(session.invalidation,.backgrounded)
        let current=session.prepare(); XCTAssertFalse(session.arm(generation:old)); XCTAssertTrue(session.arm(generation:current))
        session.observe(sample:0,map:map); XCTAssertEqual(session.stage,.playing)
        session.observe(sample:Double(map.beats[map.gapStartBeat])-map.sampleRate*2,map:map); XCTAssertEqual(session.stage,.warning)
        session.observe(sample:Double(map.beats[map.gapStartBeat]),map:map); XCTAssertEqual(session.stage,.silent)
        session.observe(sample:Double(map.beats[map.returnBeat]),map:map); XCTAssertEqual(session.stage,.returned)
        session.observe(sample:Double(map.frameCount),map:map); XCTAssertEqual(session.stage,.result); XCTAssertNil(session.invalidation)
        XCTAssertEqual(session.progress,1)
    }
    func testBackwardsOrNonfiniteClockInvalidates() throws {
        let map=try catalog().challenges[0].map
        for bad in [Double.nan,-1,99] {
            var session=ChallengeSession(); let token=session.prepare(); _=session.arm(generation:token)
            session.observe(sample:100,map:map); session.observe(sample:bad,map:map)
            XCTAssertEqual(session.stage,.result); XCTAssertEqual(session.invalidation,.discontinuity)
        }
    }
    func testHistoryCompatibleLandingOnlyAndDuplicateID() throws {
        let map=try catalog().challenges[0].map
        let assessment=Assessor.assess(events:events(map,landing:0.02),map:map)
        let trial=SavedTrial(key:key(),assessment:assessment,completed:true)
        var history=TrialHistory(); history.append(trial); history.append(trial)
        XCTAssertEqual(history.trials.count,1)
        let retry=SavedTrial(key:key(),assessment:Assessor.assess(events:events(map),map:map),completed:true)
        XCTAssertEqual(history.best(with:retry)?.id,trial.id)
        for altered in [key(challenge:"another"),key(mode:.strum),key(route:"BluetoothA2DPOutput"),key(assistance:"voiceover"),key(content:"v2"),key(device:"other"),key(system:"26.7"),key(rate:44100),key(latency:0.02)] {
            XCTAssertNil(history.best(with:SavedTrial(key:altered,assessment:assessment,completed:true)))
        }
        XCTAssertNil(SavedTrial(key:key(route:"Headphones"),assessment:assessment,completed:true).landingMagnitude)
        XCTAssertNil(SavedTrial(key:key(),assessment:assessment,completed:false).landingMagnitude)
        XCTAssertNil(SavedTrial(key:key(),assessment:.invalid(.backgrounded),completed:true).landingMagnitude)
        var partial=events(map); partial.remove(at:map.returnBeat)
        let partialAssessment=Assessor.assess(events:partial,map:map)
        XCTAssertEqual(partialAssessment.kind,.partial)
        XCTAssertNil(SavedTrial(key:key(),assessment:partialAssessment,completed:true).landingMagnitude)
    }
    func testUnavailableHistoryCannotClaimFirstOrBestAndPendingHistoryCompares() throws {
        let map=try catalog().challenges[0].map
        let first=SavedTrial(key:key(),assessment:Assessor.assess(events:events(map,landing:0.02),map:map),completed:true)
        let second=SavedTrial(key:key(),assessment:Assessor.assess(events:events(map,landing:0.01),map:map),completed:true)
        let unknown=LandingComparison(trial:first,history:TrialHistory(),historyAvailable:false)
        XCTAssertEqual(unknown.headline,"Earlier results couldn’t be read. Personal-best comparisons are unavailable.")
        XCTAssertNil(unknown.previous)
        var effective=TrialHistory(); effective.append(first); effective.append(second)
        let comparison=LandingComparison(trial:second,history:effective,historyAvailable:true)
        XCTAssertEqual(comparison.headline,"New closest landing for this challenge.")
        XCTAssertEqual(comparison.previous,"Previous compatible attempt: 20 ms from your opening pulse.")
        XCTAssertEqual(LandingComparison(trial:first,history:TrialHistory(),historyAvailable:true).headline,"Your first verified landing in these conditions.")
    }
    func testPersistenceRoundTripFailureAndCorruptionPreservation() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at:root) }
        let store=HistoryStore(url:root.appendingPathComponent("history.json"))
        XCTAssertTrue(try store.load().trials.isEmpty)
        var history=TrialHistory()
        history.append(SavedTrial(key:key(),assessment:.invalid(.cancelled),completed:false))
        try store.save(history)
        XCTAssertEqual(try store.load().trials.first?.id,history.trials.first?.id)
        let bad=Data("{broken history".utf8); try bad.write(to:store.url)
        XCTAssertThrowsError(try store.load()); XCTAssertEqual(try Data(contentsOf:store.url),bad)
        let blocked=HistoryStore(url:store.url.appendingPathComponent("impossible.json"))
        XCTAssertThrowsError(try blocked.save(history)); XCTAssertEqual(try Data(contentsOf:store.url),bad)
        history.schema=2; try JSONEncoder().encode(history).write(to:store.url)
        XCTAssertThrowsError(try store.load())
    }
    func testInterruptionsSuppressAllMetricsAcrossChallenges() throws {
        for challenge in try catalog().challenges {
            for reason in [TrialError.backgrounded,.routeChanged,.interruption,.discontinuity,.cancelled,.staleClock,.multipleTouches] {
                let assessment=Assessor.assess(events:events(challenge.map),map:challenge.map,invalidations:[reason])
                XCTAssertEqual(assessment.kind,.invalid); XCTAssertNil(assessment.score); XCTAssertNil(assessment.baseline)
            }
        }
    }
}

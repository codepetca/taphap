import Foundation
import XCTest
#if SWIFT_PACKAGE
@testable import GameCore
import Phase1Core
#else
@testable import TapHapGame
#endif
final class TrainingTests: XCTestCase {
    func challenge(_ id: String) throws -> Challenge {
        if let c=try GameTests().catalog().challenges.first(where: { $0.id == id }) { return c }
        #if SWIFT_PACKAGE
        let bundle=Bundle.module
        #else
        let bundle=Bundle(for:Self.self)
        #endif
        let catalog=try JSONDecoder().decode(TrainingCatalog.self,from:Data(contentsOf:bundle.url(forResource:"training-catalog",withExtension:"json",subdirectory:"Fixtures")!))
        try catalog.validate(); return catalog.challenges.first { $0.id == id }!
    }
    func trial(_ id: String, landing: Double=0.02, mode: InputMode = .tap, assistance: String="direct-touch", route: String="Speaker", completed: Bool=true) throws -> SavedTrial {
        let map=try challenge(id).map
        return SavedTrial(key:GameTests().key(challenge:id,mode:mode,route:route,assistance:assistance),assessment:Assessor.assess(events:GameTests().events(map,mode:mode,landing:landing),map:map),completed:completed)
    }
    func finish(_ run: TrainingRun, state: inout TrainingState, trials: inout [SavedTrial], landing: Double=0.02) throws {
        for id in run.challenges {
            let t=try trial(id,landing:landing,mode:run.mode); trials.append(t)
            XCTAssertTrue(state.accept(t,runID:run.id))
        }
        XCTAssertTrue(state.runs.last!.complete)
    }
    func date(_ day: Int) -> Date { Date(timeIntervalSince1970:Double(day)*86400+10) }
    func testCompleteBaselineDailyCheckpointTransferAndClockReversal() throws {
        var state=TrainingState(), trials:[SavedTrial]=[]
        let baseline=state.begin(mode:.tap,date:date(100),trials:trials)!
        XCTAssertEqual(baseline.kind,.baseline); XCTAssertEqual(baseline.challenges.count,3)
        try finish(baseline,state:&state,trials:&trials,landing:0.08)
        for day in 101...103 {
            let run=state.begin(mode:.tap,date:date(day),trials:trials)!
            XCTAssertEqual(run.kind,.daily)
            let duration=try run.challenges.reduce(0.0) { total,id in let m=try challenge(id).map; return total+Double(m.frameCount)/m.sampleRate }
            XCTAssertTrue((180...300).contains(duration))
            XCTAssertFalse(run.challenges.contains("transfer-paperkite"))
            try finish(run,state:&state,trials:&trials)
            XCTAssertNil(state.begin(mode:.tap,date:date(day),trials:trials))
        }
        let checkpoint=state.begin(mode:.tap,date:date(104),trials:trials)!
        XCTAssertEqual(checkpoint.kind,.checkpoint); XCTAssertEqual(checkpoint.challenges,baseline.challenges)
        try finish(checkpoint,state:&state,trials:&trials)
        let summary=TrainingSummary(run:state.runs.last!,trials:trials)!
        XCTAssertTrue(summary.change(from:TrainingSummary(run:state.runs.first!,trials:trials)!)!.contains("60.0 ms lower"))
        let transfer=state.begin(mode:.tap,date:date(104),trials:trials)!
        XCTAssertEqual(transfer.kind,.transfer); try finish(transfer,state:&state,trials:&trials)
        XCTAssertNil(TrainingSummary(run:state.runs.last!,trials:trials)!.change(from:summary))
        XCTAssertEqual(state.day(at:date(2)),104)
        XCTAssertEqual(state.begin(mode:.strum,date:date(104),trials:trials)?.kind,.baseline)
    }
    func testMedianRejectsLuckyOutlierAndPartialIncompatibleAssistedDuplicate() throws {
        var state=TrainingState(); let run=state.begin(mode:.tap,date:date(100),trials:[])!
        for bad in [try trial("first-light",assistance:"outside-timing-help"),try trial("first-light",mode:.strum),try trial("first-light",route:"BluetoothA2DPOutput"),try trial("first-light",completed:false),try trial("stay-a-little")] {
            XCTAssertFalse(state.accept(bad,runID:run.id))
        }
        let a=try trial("first-light",landing:0.08)
        XCTAssertTrue(state.accept(a,runID:run.id)); XCTAssertFalse(state.accept(a,runID:run.id))
        let map=try challenge("first-light").map
        var events=GameTests().events(map); events.remove(at:map.returnBeat)
        let partial=SavedTrial(key:a.key,assessment:Assessor.assess(events:events,map:map),completed:true)
        XCTAssertFalse(state.accept(partial,runID:run.id)); XCTAssertNil(partial.reward)
        XCTAssertNil(TrainingSummary(run:state.runs[0],trials:[a]))
        let b=try trial("first-light",landing:0), c=try trial("first-light",landing:0.09)
        XCTAssertTrue(state.accept(b,runID:run.id)); XCTAssertTrue(state.accept(c,runID:run.id))
        XCTAssertEqual(TrainingSummary(run:state.runs[0],trials:[a,b,c])!.landing,80,accuracy:0.001)
        XCTAssertNil(try trial("first-light",assistance:"direct-touch-voiceover").reward)
    }
    func testResumeRestartAndRouteCompatibilityNeverMix() throws {
        var state=TrainingState(); let run=state.begin(mode:.tap,date:date(100),trials:[])!
        let first=try trial("first-light"); XCTAssertTrue(state.accept(first,runID:run.id))
        let reloaded=try JSONDecoder().decode(TrainingState.self,from:JSONEncoder().encode(state))
        XCTAssertEqual(reloaded.active(mode:.tap)?.trialIDs,[first.id])
        XCTAssertEqual(state.begin(mode:.tap,date:date(102),trials:[first])?.id,run.id)
        let changed=SavedTrial(key:GameTests().key(latency:0.021),assessment:first.assessment,completed:true)
        XCTAssertFalse(state.accept(changed,runID:run.id))
        state.abandon(mode:.tap)
        let replacement=state.begin(mode:.tap,date:date(102),trials:[first])!
        XCTAssertNotEqual(replacement.id,run.id); XCTAssertTrue(replacement.trialIDs.isEmpty)
        XCTAssertFalse(state.accept(try trial("first-light"),runID:run.id))
    }
    func testSchemaOneMigrationPreservesEveryTrialAndRejectsCorruptSession() throws {
        let trial=try trial("first-light")
        struct Legacy: Encodable { let schema=1; let trials:[SavedTrial] }
        let raw=try JSONEncoder().encode(Legacy(trials:[trial]))
        var migrated=try JSONDecoder().decode(TrialHistory.self,from:raw)
        XCTAssertEqual(migrated.schema,2); XCTAssertEqual(migrated.trials[0].id,trial.id)
        XCTAssertEqual(migrated.trials[0].assessment,trial.assessment); XCTAssertTrue(migrated.training.runs.isEmpty)
        let run=migrated.training.begin(mode:.tap,date:date(100),trials:migrated.trials)!
        XCTAssertTrue(migrated.training.accept(trial,runID:run.id))
        try migrated.validate()
        migrated.training.runs[0].trialIDs.append(UUID())
        XCTAssertThrowsError(try migrated.validate())
        XCTAssertThrowsError(try JSONDecoder().decode(TrialHistory.self,from:JSONEncoder().encode(migrated)))
    }
    func testAllAdaptiveDimensionsMapsAndPatternScoring() throws {
        for song in ["tidepool","lantern"] {
            for level in 0...3 {
                for p in 0...1 {
                    let c=try challenge("\(song)-l\(level)-p\(p)")
                    for mode in [InputMode.tap,.strum] {
                        XCTAssertEqual(try trial(c.id,mode:mode).assessment.kind,.scored)
                    }
                    XCTAssertEqual(c.pattern,level == 3 ? "spaced" : "pulse")
                    let envelope=try GapEnvelope(map:c.map)
                    XCTAssertEqual(envelope.gain(at:envelope.returnStart-1),0)
                    XCTAssertEqual(envelope.gain(at:envelope.fullReturn),1)
                }
            }
        }
        XCTAssertNotEqual(try challenge("tidepool-l0-p0").map.beats,try challenge("lantern-l0-p0").map.beats)
        XCTAssertNotEqual(try challenge("tidepool-l0-p0").map.gapStartBeat,try challenge("tidepool-l0-p1").map.gapStartBeat)
    }
    func testChaptersRequireCompleteStrongSessionsOnDifferentDays() throws {
        var state=TrainingState(), trials:[SavedTrial]=[]
        let baseline=state.begin(mode:.tap,date:date(100),trials:trials)!
        try finish(baseline,state:&state,trials:&trials)
        XCTAssertEqual(state.earnedLevel(mode:.tap,trials:trials),0)
        for day in 101...102 {
            let run=state.begin(mode:.tap,date:date(day),trials:trials)!
            try finish(run,state:&state,trials:&trials)
            XCTAssertEqual(state.earnedLevel(mode:.tap,trials:trials),day == 101 ? 0 : 1)
        }
        XCTAssertEqual(state.earnedLevel(mode:.strum,trials:trials),0)
    }
}

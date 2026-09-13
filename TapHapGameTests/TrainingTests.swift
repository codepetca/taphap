import Foundation
import XCTest
#if SWIFT_PACKAGE
@testable import GameCore
import Phase1Core
#else
@testable import TapHapGame
#endif
final class TrainingTests: XCTestCase {
    let content=TrainingContent(benchmark:"v1",training:"v1")
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
    func trial(_ id: String, landing: Double=0.02, mode: InputMode = .tap, assistance: String="direct-touch", route: String="Speaker", completed: Bool=true, association: TrainingAttempt? = nil, revision: String="v1") throws -> SavedTrial {
        let map=try challenge(id).map
        return SavedTrial(key:GameTests().key(challenge:id,mode:mode,route:route,assistance:assistance,content:revision),assessment:Assessor.assess(events:GameTests().events(map,mode:mode,landing:landing),map:map),completed:completed,training:association)
    }
    func finish(_ run: TrainingRun, state: inout TrainingState, trials: inout [SavedTrial], landing: Double=0.02) throws {
        for (index,id) in run.challenges.enumerated() {
            let t=try trial(id,landing:landing,mode:run.mode,association:TrainingAttempt(runID:run.id,step:index)); trials.append(t)
            XCTAssertTrue(state.accept(t,runID:run.id))
        }
        XCTAssertTrue(state.runs.last!.complete)
    }
    func date(_ day: Int) -> Date { Date(timeIntervalSince1970:Double(day)*86400+10) }
    func testCompleteBaselineDailyCheckpointTransferAndClockReversal() throws {
        var state=TrainingState(), trials:[SavedTrial]=[]
        let baseline=state.begin(mode:.tap,date:date(100),trials:trials,content:content)!
        XCTAssertEqual(baseline.kind,.baseline); XCTAssertEqual(baseline.challenges.count,3)
        try finish(baseline,state:&state,trials:&trials,landing:0.08)
        for day in 101...103 {
            let run=state.begin(mode:.tap,date:date(day),trials:trials,content:content)!
            XCTAssertEqual(run.kind,.daily)
            let duration=try run.challenges.reduce(0.0) { total,id in let m=try challenge(id).map; return total+Double(m.frameCount)/m.sampleRate }
            XCTAssertTrue((180...300).contains(duration))
            XCTAssertFalse(run.challenges.contains("transfer-paperkite"))
            try finish(run,state:&state,trials:&trials)
            XCTAssertNil(state.begin(mode:.tap,date:date(day),trials:trials,content:content))
        }
        let checkpoint=state.begin(mode:.tap,date:date(104),trials:trials,content:content)!
        XCTAssertEqual(checkpoint.kind,.checkpoint); XCTAssertEqual(checkpoint.challenges,baseline.challenges)
        try finish(checkpoint,state:&state,trials:&trials)
        let summary=TrainingSummary(run:state.runs.last!,trials:trials)!
        XCTAssertTrue(summary.change(from:TrainingSummary(run:state.runs.first!,trials:trials)!)!.contains("60.0 ms lower"))
        let transfer=state.begin(mode:.tap,date:date(104),trials:trials,content:content)!
        XCTAssertEqual(transfer.kind,.transfer); try finish(transfer,state:&state,trials:&trials)
        XCTAssertNil(TrainingSummary(run:state.runs.last!,trials:trials)!.change(from:summary))
        XCTAssertEqual(state.day(at:date(2)),104)
        XCTAssertEqual(state.begin(mode:.strum,date:date(104),trials:trials,content:content)?.kind,.baseline)
    }
    func testMedianRejectsLuckyOutlierAndPartialIncompatibleAssistedDuplicate() throws {
        var state=TrainingState(); let run=state.begin(mode:.tap,date:date(100),trials:[],content:content)!
        let association=TrainingAttempt(runID:run.id,step:0)
        for bad in [try trial("first-light",assistance:"outside-timing-help",association:association),try trial("first-light",mode:.strum,association:association),try trial("first-light",route:"BluetoothA2DPOutput",association:association),try trial("first-light",completed:false,association:association),try trial("stay-a-little",association:association)] {
            XCTAssertFalse(state.accept(bad,runID:run.id))
        }
        let a=try trial("first-light",landing:0.08,association:TrainingAttempt(runID:run.id,step:0))
        XCTAssertTrue(state.accept(a,runID:run.id)); XCTAssertFalse(state.accept(a,runID:run.id))
        let map=try challenge("first-light").map
        var events=GameTests().events(map); events.remove(at:map.returnBeat)
        let partial=SavedTrial(key:a.key,assessment:Assessor.assess(events:events,map:map),completed:true,training:TrainingAttempt(runID:run.id,step:1))
        XCTAssertFalse(state.accept(partial,runID:run.id)); XCTAssertNil(partial.reward)
        XCTAssertNil(TrainingSummary(run:state.runs[0],trials:[a]))
        let b=try trial("first-light",landing:0,association:TrainingAttempt(runID:run.id,step:1)), c=try trial("first-light",landing:0.09,association:TrainingAttempt(runID:run.id,step:2))
        XCTAssertTrue(state.accept(b,runID:run.id)); XCTAssertTrue(state.accept(c,runID:run.id))
        XCTAssertEqual(TrainingSummary(run:state.runs[0],trials:[a,b,c])!.landing,80,accuracy:0.001)
        XCTAssertNil(try trial("first-light",assistance:"direct-touch-voiceover").reward)
    }
    func testResumeRestartAndRouteCompatibilityNeverMix() throws {
        var state=TrainingState(); let run=state.begin(mode:.tap,date:date(100),trials:[],content:content)!
        let first=try trial("first-light",association:TrainingAttempt(runID:run.id,step:0)); XCTAssertTrue(state.accept(first,runID:run.id))
        let reloaded=try JSONDecoder().decode(TrainingState.self,from:JSONEncoder().encode(state))
        XCTAssertEqual(reloaded.active(mode:.tap)?.trialIDs,[first.id])
        XCTAssertEqual(state.begin(mode:.tap,date:date(102),trials:[first],content:content)?.id,run.id)
        XCTAssertEqual(state.latestDay,100) // Resuming does not invent a later saved session day.
        let changed=SavedTrial(key:GameTests().key(latency:0.021),assessment:first.assessment,completed:true,training:TrainingAttempt(runID:run.id,step:1))
        XCTAssertFalse(state.accept(changed,runID:run.id))
        state.abandon(mode:.tap)
        let replacement=state.begin(mode:.tap,date:date(102),trials:[first],content:content)!
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
        let run=migrated.training.begin(mode:.tap,date:date(100),trials:migrated.trials,content:content)!
        XCTAssertFalse(migrated.training.accept(trial,runID:run.id))
        XCTAssertNil(migrated.trials.first!.training)
        let bound=try self.trial("first-light",association:TrainingAttempt(runID:run.id,step:0))
        migrated.append(bound)
        XCTAssertTrue(migrated.training.accept(bound,runID:run.id))
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
        let baseline=state.begin(mode:.tap,date:date(100),trials:trials,content:content)!
        try finish(baseline,state:&state,trials:&trials)
        XCTAssertEqual(state.earnedLevel(mode:.tap,trials:trials,content:content),0)
        for day in 101...102 {
            let run=state.begin(mode:.tap,date:date(day),trials:trials,content:content)!
            try finish(run,state:&state,trials:&trials)
            XCTAssertEqual(state.earnedLevel(mode:.tap,trials:trials,content:content),day == 101 ? 0 : 1)
        }
        XCTAssertEqual(state.earnedLevel(mode:.strum,trials:trials,content:content),0)
    }
    func testBoundAttemptsAndPinnedContentRejectOldOrUpdatedInputsAfterReload() throws {
        var state=TrainingState(), trials:[SavedTrial]=[]
        let baseline=state.begin(mode:.tap,date:date(100),trials:trials,content:content)!
        XCTAssertFalse(state.accept(try trial("first-light"),runID:baseline.id))
        let wrongStep=try trial("first-light",association:TrainingAttempt(runID:baseline.id,step:1))
        XCTAssertFalse(state.accept(wrongStep,runID:baseline.id))
        try finish(baseline,state:&state,trials:&trials)
        let daily=state.begin(mode:.tap,date:date(101),trials:trials,content:content)!
        let warmup=try trial(daily.challenges[0],association:TrainingAttempt(runID:daily.id,step:0))
        trials.append(warmup); XCTAssertTrue(state.accept(warmup,runID:daily.id))
        state=try JSONDecoder().decode(TrainingState.self,from:JSONEncoder().encode(state))
        let updated=try trial(daily.challenges[1],association:TrainingAttempt(runID:daily.id,step:1),revision:"re-authored-v2")
        XCTAssertFalse(state.accept(updated,runID:daily.id)); XCTAssertFalse(state.runs.last!.complete)
        XCTAssertEqual(state.runs.last!.trialIDs,[warmup.id])
        XCTAssertEqual(state.earnedLevel(mode:.tap,trials:trials+[updated],content:content),0)
    }
    func testParseableProgressCorruptionIsPreservedAndRejected() throws {
        var history=TrialHistory(), trials:[SavedTrial]=[]
        let baseline=history.training.begin(mode:.tap,date:date(100),trials:trials,content:content)!
        try finish(baseline,state:&history.training,trials:&trials)
        let daily=history.training.begin(mode:.tap,date:date(101),trials:trials,content:content)!
        try finish(daily,state:&history.training,trials:&trials)
        trials.forEach { history.append($0) }; try history.validate()
        let original=try JSONSerialization.jsonObject(with:JSONEncoder().encode(history)) as! [String:Any]
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at:root) }
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        let store=HistoryStore(url:root.appendingPathComponent("history.json"))
        for mutation in 0..<7 {
            var object=original, training=original["training"] as! [String:Any]
            var runs=training["runs"] as! [[String:Any]]
            switch mutation {
            case 0: training["latestDay"]=99
            case 1: runs[0]["kind"]="transfer"
            case 2: runs[1]["challenges"]=Array(repeating:"first-light",count:4)
            case 3: runs[1]["abandoned"]=true
            case 4: runs[1]["day"]=99
            case 5: runs[1]["content"]=["benchmark":"v1","training":"new-content"]
            default: training["latestDay"]=2000000
            }
            training["runs"]=runs; object["training"]=training
            let bytes=try JSONSerialization.data(withJSONObject:object)
            try bytes.write(to:store.url)
            XCTAssertThrowsError(try store.load(),"Mutation \(mutation)")
            XCTAssertEqual(try Data(contentsOf:store.url),bytes)
        }
    }

    func testEveryRejectedAttemptKeepsAValidPlanAssociation() throws {
        var history=TrialHistory()
        let run=history.training.begin(mode:.tap,date:date(100),trials:[],content:content)!
        let association=TrainingAttempt(runID:run.id,step:0)
        let good=try trial("first-light",association:association)
        for _ in 0..<2 {
            history.append(SavedTrial(key:good.key,assessment:.invalid(.interruption),completed:false,training:association))
        }
        try history.validate() // Multiple genuine failed attempts can refer to the same unfinished step.
        history.append(good); XCTAssertTrue(history.training.accept(good,runID:run.id))
        try history.validate()
        let original=try JSONSerialization.jsonObject(with:JSONEncoder().encode(history)) as! [String:Any]
        for mutation in 0..<5 {
            var object=original, records=original["trials"] as! [[String:Any]]
            var rejected=records[0], binding=rejected["training"] as! [String:Any]
            var key=rejected["key"] as! [String:Any]
            switch mutation {
            case 0: binding["runID"]=UUID().uuidString
            case 1: binding["step"] = -1
            case 2: binding["step"]=3
            case 3: key["challenge"]="stay-a-little"
            default: key["content"]="other-map-revision"
            }
            rejected["training"]=binding; rejected["key"]=key; records[0]=rejected; object["trials"]=records
            let raw=try JSONSerialization.data(withJSONObject:object)
            XCTAssertThrowsError(try JSONDecoder().decode(TrialHistory.self,from:raw))
        }
    }

}

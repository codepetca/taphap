import XCTest
import AVFAudio
import UIKit
import SwiftUI
@testable import TapHapGame

@MainActor
final class IntegrationTests: XCTestCase {
    func testAllRenderedGapsAreZeroWithUnchangedTimeline() throws {
        let catalog=try GameAudioPlayer.loadCatalog()
        for challenge in catalog.challenges {
            let url=Bundle.main.url(forResource:challenge.songTitle,withExtension:"wav")!
            let file=try AVAudioFile(forReading:url)
            let original=AVAudioPCMBuffer(pcmFormat:file.processingFormat,frameCapacity:AVAudioFrameCount(file.length))!
            try file.read(into:original)
            let (map,buffer)=try GameAudioPlayer.loadBuffer(challengeID:challenge.id)
            let envelope=try GapEnvelope(map:map)
            XCTAssertEqual(buffer.frameLength,original.frameLength)
            let samples=buffer.floatChannelData![0], source=original.floatChannelData![0]
            var gapPeak:Float=0, returnPeak:Float=0
            for frame in 0..<Int(buffer.frameLength) {
                if frame >= envelope.silentStart, frame < envelope.returnStart { gapPeak=max(gapPeak,abs(samples[frame])) }
                if frame < envelope.fadeStart || frame >= envelope.fullReturn { XCTAssertEqual(samples[frame],source[frame]) }
                if frame >= envelope.fullReturn { returnPeak=max(returnPeak,abs(samples[frame])) }
            }
            XCTAssertEqual(gapPeak,0); XCTAssertGreaterThan(returnPeak,0.1)
        }
    }
    func makeModel() -> GameModel {
        GameModel(store:HistoryStore(url:FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("history.json")))
    }
    func testEveryPreparationInvalidationCancelsDeferredArming() throws {
        for reason in [TrialError.backgrounded,.routeChanged,.interruption,.discontinuity] {
            let model=makeModel(); model.choose(0)
            var pending:(() -> Void)?
            model.start { pending=$0 }
            model.environmentChanged(UIApplication.willResignActiveNotification,reason:reason)
            pending?()
            XCTAssertFalse(model.active); XCTAssertFalse(model.audio.engine.isRunning)
            XCTAssertNil(model.result?.assessment.score)
        }
    }
    func testMediaResetRetryAndHistoryReload() throws {
        let model=makeModel(); model.choose(0)
        model.start { _ in }
        model.environmentChanged(AVAudioSession.mediaServicesWereResetNotification,reason:.discontinuity)
        XCTAssertFalse(model.active)
        model.retry(); model.start { _ in }
        model.finish(reason:.cancelled)
        XCTAssertEqual(model.screen,"result"); XCTAssertEqual(model.result?.assessment.kind,.invalid)
        let reloaded=GameModel(store:model.store)
        XCTAssertEqual(reloaded.history.trials.count,model.history.trials.count)
        model.next(); XCTAssertEqual(model.selection,1); XCTAssertEqual(model.screen,"play")
        model.home(); XCTAssertEqual(model.screen,"selection")
    }
    func testFailedSaveRetainsPendingAttemptsAndRetriesWithoutDuplicates() throws {
        let model=makeModel()
        // Create a file where the history directory must go, after the successful empty load.
        let folder=model.store.url.deletingLastPathComponent()
        try Data("storage obstruction".utf8).write(to:folder)
        for _ in 0..<2 {
            model.choose(0); model.start { _ in }; model.finish(reason:.cancelled)
        }
        XCTAssertTrue(model.canRetrySave); XCTAssertEqual(model.history.trials.count,0)
        try FileManager.default.removeItem(at:folder)
        model.retrySave(); model.retrySave()
        XCTAssertFalse(model.canRetrySave); XCTAssertEqual(model.history.trials.count,2)
        XCTAssertEqual(try model.store.load().trials.count,2)
    }
    func scoredTrial(_ model: GameModel, landing: Double) throws -> SavedTrial {
        let map=model.catalog!.challenges[0].map
        let events=map.beats.indices.map { index in
            let time=map.seconds(index)+0.04+(index >= map.gapStartBeat ? landing : 0)
            return InputEvent(trackSeconds:time,hostSeconds:100+time,observedHostSeconds:100+time+0.01,mode:.tap)
        }
        let key=ComparisonKey(content:"fixture-v1",challenge:"first-light",mode:.tap,device:"fixture",system:"26",route:"Speaker",sampleRate:48000,bufferDuration:0.005,outputLatency:0.015,assistance:"direct-touch")
        let result=SavedTrial(key:key,assessment:Assessor.assess(events:events,map:map),completed:true)
        XCTAssertNotNil(result.landingMagnitude)
        return result
    }
    func testScoredAttemptsRespectUnknownHistoryAndConsecutivePendingSaves() throws {
        let store=makeModel().store
        try FileManager.default.createDirectory(at:store.url.deletingLastPathComponent(),withIntermediateDirectories:true)
        let corrupt=Data("unreadable earlier history".utf8); try corrupt.write(to:store.url)
        let unknown=GameModel(store:store), first=try scoredTrial(unknown,landing:0.02)
        unknown.persist(first)
        XCTAssertEqual(unknown.comparison(for:first).headline,"Earlier results couldn’t be read. Personal-best comparisons are unavailable.")
        XCTAssertNil(unknown.comparison(for:first).previous)
        XCTAssertEqual(try Data(contentsOf:store.url),corrupt)
        let pending=makeModel(), second=try scoredTrial(pending,landing:0.01)
        let obstruction=pending.store.url.deletingLastPathComponent()
        try Data("storage obstruction".utf8).write(to:obstruction)
        pending.persist(first); pending.persist(second)
        XCTAssertEqual(pending.history.trials.count,0); XCTAssertTrue(pending.canRetrySave)
        let expected=pending.comparison(for:second)
        XCTAssertEqual(expected.headline,"New closest landing for this challenge.")
        XCTAssertEqual(expected.previous,"Previous compatible attempt: 20 ms from your opening pulse.")
        try FileManager.default.removeItem(at:obstruction); pending.retrySave()
        XCTAssertEqual(pending.history.trials.count,2)
        XCTAssertEqual(pending.comparison(for:second),expected)
    }
    func testSyntheticOccurrenceTimestampsProduceDurableFullScore() async throws {
        try await verifyRenderedFixture(challengeID:"first-light",mode:.tap)
    }
    func testNewSpacedStrumMapOnActualRenderTimeline() async throws {
        try await verifyRenderedFixture(challengeID:"lantern-l3-p1",mode:.strum)
    }
    private func verifyRenderedFixture(challengeID: String, mode: InputMode) async throws {
        let model=makeModel(); model.mode=mode
        model.choose(model.catalog!.challenges.firstIndex { $0.id == challengeID }!); model.start()
        let map=model.challenge!.map
        // Software occurrence fixture, not physical contact or observed musician performance.
        for i in map.beats.indices {
            let timestamp=model.audio.scheduledHostSeconds+map.seconds(i)+0.04
            let delay=timestamp-GameAudioPlayer.hostNow()+0.008
            if delay > 0 { try await Task.sleep(for:.seconds(delay)) }
            model.capture(hostSeconds:timestamp,direction:mode == .strum ? .down : nil)
        }
        let deadline=Date().addingTimeInterval(3)
        while model.active && Date() < deadline { try await Task.sleep(for:.milliseconds(40)) }
        XCTAssertEqual(model.result?.assessment.kind,.scored)
        XCTAssertEqual(model.result?.assessment.score?.reentryMS ?? 999,0,accuracy:2)
        XCTAssertNotNil(model.result?.landingMagnitude)
        XCTAssertEqual(try model.store.load().trials.first?.id,model.result?.id)
        let window=UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows).first { $0.isKeyWindow }!
        let original=window.rootViewController
        defer { window.rootViewController=original }
        window.rootViewController=UIHostingController(rootView:GameView(model:model))
        window.layoutIfNeeded()
        try await Task.sleep(for:.milliseconds(250))
        let image=UIGraphicsImageRenderer(bounds:window.bounds).image { _ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true) }
        let attachment=XCTAttachment(image:image); attachment.name="result-scored-software-fixture"; attachment.lifetime = .keepAlways
        add(attachment)
    }
    func testSurfaceHasSilentDirectTouchAccessibilityAndLargeTarget() {
        let surface=GameTouchView(frame:CGRect(x:0,y:0,width:350,height:300))
        XCTAssertTrue(surface.isAccessibilityElement)
        XCTAssertTrue(surface.accessibilityTraits.contains(.allowsDirectInteraction))
        XCTAssertTrue(surface.accessibilityDirectTouchOptions.contains(.silentOnTouch))
        XCTAssertEqual(surface.accessibilityIdentifier,"playSurface")
    }
    func testActualRenderClockTraversesSongWithoutInputsAndPersistsInvalidResult() async throws {
        let model=makeModel(); model.choose(0); model.start()
        let deadline=Date().addingTimeInterval(40)
        var stages=Set<String>()
        while model.active && Date() < deadline {
            stages.insert(model.session.stage.rawValue)
            try await Task.sleep(for:.milliseconds(40))
        }
        XCTAssertFalse(model.active); XCTAssertEqual(model.screen,"result")
        XCTAssertTrue(stages.isSuperset(of:["playing","warning","silent","returned"]))
        XCTAssertEqual(model.result?.assessment.kind,.invalid)
        XCTAssertEqual(model.history.trials.count,1)
        XCTAssertGreaterThan(model.audio.anchorCount,500)
        XCTAssertLessThan(model.audio.maximumClockResidualMS,2)
        print("PHASE2_RENDER anchors=\(model.audio.anchorCount) residualMS=\(model.audio.maximumClockResidualMS) stages=\(stages.sorted())")
    }
}

@MainActor
final class TrainingIntegrationTests: XCTestCase {
    func testSessionCreationAndStepFailureAreAtomicAndResumeAfterReload() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at:root) }
        let store=HistoryStore(url:root.appendingPathComponent("history.json"))
        let model=GameModel(store:store)
        model.beginTraining()
        XCTAssertEqual(model.currentTrainingRun?.trialIDs.count,0)
        let runID=model.currentTrainingRun!.id
        let fixture=try IntegrationTests().scoredTrial(model,landing:0.02)
        // A blocked destination leaves both summary and step unchanged on disk.
        let original=try Data(contentsOf:store.url)
        try FileManager.default.removeItem(at:store.url)
        try FileManager.default.createDirectory(at:store.url,withIntermediateDirectories:false)
        model.persist(fixture)
        XCTAssertTrue(model.canRetrySave)
        XCTAssertEqual(model.currentTrainingRun?.trialIDs.count,0)
        model.continueTraining(); XCTAssertEqual(model.currentTrainingRun?.trialIDs.count,0)
        try FileManager.default.removeItem(at:store.url)
        try original.write(to:store.url)
        model.retrySave()
        XCTAssertFalse(model.canRetrySave)
        XCTAssertEqual(model.currentTrainingRun?.trialIDs,[fixture.id])
        let reloaded=GameModel(store:store); reloaded.beginTraining()
        XCTAssertEqual(reloaded.currentTrainingRun?.id,runID)
        XCTAssertEqual(reloaded.currentTrainingRun?.trialIDs,[fixture.id])
        XCTAssertEqual(reloaded.history.trials.count,1)
        reloaded.restartTraining()
        XCTAssertNotEqual(reloaded.currentTrainingRun?.id,runID)
        XCTAssertEqual(reloaded.history.trials.count,1)
        XCTAssertTrue(reloaded.history.training.runs.first!.abandoned)
    }
    func testUnknownHistoryAndFailedCreationNeverStartTraining() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at:root) }
        let store=HistoryStore(url:root.appendingPathComponent("history.json"))
        let model=GameModel(store:store)
        try Data("obstruction".utf8).write(to:root)
        model.beginTraining(); XCTAssertEqual(model.screen,"selection"); XCTAssertNil(model.trainingRunID)
        try FileManager.default.removeItem(at:root)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        let corrupt=Data("corrupt".utf8); try corrupt.write(to:store.url)
        let unknown=GameModel(store:store); unknown.beginTraining()
        XCTAssertFalse(unknown.trainingAvailable); XCTAssertEqual(try Data(contentsOf:store.url),corrupt)
    }
}

import AVFAudio
import SwiftUI
import UIKit

@MainActor
final class GameModel: ObservableObject {
    @Published var outsideHelp = false
    @Published private(set) var trainingRunID: UUID?
    private let clock: () -> Date
    @Published var fixtureDate: Date?
    static var uiFixture: Bool {
        #if DEBUG && targetEnvironment(simulator)
        return ProcessInfo.processInfo.arguments.contains("-phase3-ui-fixture")
        #else
        return false
        #endif
    }
    private func now() -> Date { Self.uiFixture ? (fixtureDate ?? clock()) : clock() }
    @Published var mode: InputMode = .tap
    @Published private(set) var session = ChallengeSession()
    @Published private(set) var selection = 0
    @Published private(set) var screen = "selection"
    @Published private(set) var history = TrialHistory()
    @Published private(set) var result: SavedTrial?
    @Published private(set) var storageMessage: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var catalog: SongCatalog?
    let audio = GameAudioPlayer()
    let store: HistoryStore
    private var historyWritable = true
    private var pendingSave: TrialHistory?
    private var key: ComparisonKey?
    private var events: [InputEvent] = []
    private var brackets: [Double] = []
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []
    private var startHost = 0.0
    private var savedIdleDisabled = false
    var challenge: Challenge? { catalog?.challenges[selection] }
    var running: Bool { session.active && session.stage != .preparing }
    var active: Bool { session.active }

    init(store: HistoryStore? = nil, now: @escaping () -> Date = Date.init) {
        self.clock=now
        let folder=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("TapHap",isDirectory:true)
        if Self.uiFixture {
            let identifier=UUID(uuidString:ProcessInfo.processInfo.environment["TAPHAP_UI_FIXTURE_ID"] ?? "") ?? UUID()
            self.store=HistoryStore(url:FileManager.default.temporaryDirectory.appendingPathComponent("TrainingFixtures/\(identifier)/history.json"))
        } else { self.store=store ?? HistoryStore(url:folder.appendingPathComponent("history.json")) }
        do { catalog=try GameAudioPlayer.loadCatalog() } catch { errorMessage="The song could not be verified. Please reinstall this build." }
        do { history=try self.store.load() } catch {
            historyWritable=false; storageMessage="Saved history couldn’t be read. It has been preserved. You can play, but new attempts won’t be saved."
        }
        let center=NotificationCenter.default
        for (notification,reason) in [(AVAudioSession.routeChangeNotification,TrialError.routeChanged),
                                      (AVAudioSession.interruptionNotification,.interruption),
                                      (AVAudioSession.mediaServicesWereResetNotification,.discontinuity),
                                      (NSNotification.Name.AVAudioEngineConfigurationChange,.discontinuity),
                                      (UIApplication.willResignActiveNotification,.backgrounded),
                                      (UIAccessibility.voiceOverStatusDidChangeNotification,.interruption)] {
            observers.append(center.addObserver(forName:notification,object:nil,queue:.main) { [weak self] _ in
                MainActor.assumeIsolated { self?.environmentChanged(notification,reason:reason) }
            })
        }
    }
    func choose(_ index: Int, training: Bool = false) {
        guard !active, catalog?.challenges.indices.contains(index) == true else { return }
        if !training { trainingRunID=nil }
        selection=index; screen="play"; result=nil; session=ChallengeSession(); errorMessage=nil
    }
    func home() { guard !active else { return }; screen="selection"; result=nil; trainingRunID=nil }
    func retry() { choose(selection,training:trainingRunID != nil) }
    func next() { guard let catalog else { return }; choose((selection+1)%min(3,catalog.challenges.count)) }
    func environmentChanged(_ notification: Notification.Name, reason: TrialError) {
        if active { finish(reason:reason) }
        if notification == AVAudioSession.mediaServicesWereResetNotification { audio.rebuildAfterMediaServicesReset() }
    }
    func start(deferArming: (@escaping @MainActor @Sendable () -> Void) -> Void = { action in DispatchQueue.main.async { action() } }) {
        guard !active, screen == "play", let challenge else { return }
        if let run=currentTrainingRun, run.content.revision(for:challenge.id) != contentIdentity.revision(for:challenge.id) {
            errorMessage="This saved step uses an earlier song version. Your attempts are preserved. Restart the session from Home to use this version."
            return
        }
        #if DEBUG && targetEnvironment(simulator)
        if Self.uiFixture { completeUIFixture(challenge); return }
        #endif
        let generation=session.prepare()
        result=nil; events=[]; brackets=[]; key=nil; errorMessage=nil
        savedIdleDisabled=UIApplication.shared.isIdleTimerDisabled
        UIApplication.shared.isIdleTimerDisabled=true
        do {
            try audio.start(challengeID:challenge.id)
            guard session.active, generation == session.generation else { audio.stop(); return }
            let route=AVAudioSession.sharedInstance()
            guard route.currentRoute.outputs.count == 1, route.currentRoute.outputs.first?.portType == .builtInSpeaker else {
                throw TrialError.routeChanged
            }
            var info=utsname(); uname(&info)
            let machineSize=MemoryLayout.size(ofValue:info.machine)
            let device=withUnsafePointer(to:&info.machine) { pointer in
                pointer.withMemoryRebound(to:CChar.self,capacity:machineSize) { String(cString:$0) }
            }
            key=ComparisonKey(content:challenge.song == nil ? ContentRevision.catalogSHA256 : TrainingContentRevision.catalogSHA256,challenge:challenge.id,mode:mode,device:device,
                              system:UIDevice.current.systemVersion,route:route.currentRoute.outputs[0].portType.rawValue,
                              sampleRate:route.sampleRate,bufferDuration:route.ioBufferDuration,outputLatency:route.outputLatency,
                              assistance:outsideHelp ? "outside-timing-help" : UIAccessibility.isVoiceOverRunning ? "direct-touch-voiceover" : "direct-touch")
            startHost=GameAudioPlayer.hostNow()
            deferArming { [weak self] in
                guard let self, self.session.generation == generation, self.active else { return }
                guard UIApplication.shared.applicationState == .active else { self.finish(reason:.backgrounded); return }
                guard self.session.arm(generation:generation) else { return }
                self.timer=Timer.scheduledTimer(withTimeInterval:1.0/30,repeats:true) { [weak self] _ in
                    MainActor.assumeIsolated { self?.observe() }
                }
            }
        } catch {
            finish(reason:error as? TrialError ?? .invalidClock)
            if key == nil {
                errorMessage = (error as? TrialError) == .routeChanged
                    ? "Use the iPhone’s built-in speaker, then try again. Other outputs haven’t been validated for this build."
                    : "The song couldn’t start reliably. Try again. If it keeps happening, reopen the app."
            }
        }
    }
    func observe() {
        guard running, let challenge else { return }
        do {
            guard let anchor=try audio.anchor() else {
                if GameAudioPlayer.hostNow()-startHost > 1 { finish(reason:.invalidClock) }
                return
            }
            guard abs(GameAudioPlayer.hostNow()-anchor.hostSeconds) < 0.25 else { finish(reason:.staleClock); return }
            session.observe(sample:anchor.sample,map:challenge.map)
            if session.stage == .result { finalize(reason:session.invalidation) }
        } catch { finish(reason:error as? TrialError ?? .invalidClock) }
    }
    func capture(hostSeconds: Double, direction: StrokeDirection?, bracketSeconds: Double? = nil) {
        guard running, let challenge else { return }
        do {
            let now=GameAudioPlayer.hostNow()
            // Touches before scheduled playback have no track-time meaning.
            guard hostSeconds >= audio.scheduledHostSeconds else { return }
            guard let anchor=try audio.anchor() else { throw TrialError.invalidClock }
            let track=try anchor.trackSeconds(touchHostSeconds:hostSeconds,observedHostSeconds:now)
            guard track >= 0, track < Double(challenge.map.frameCount)/challenge.map.sampleRate else { return }
            events.append(InputEvent(trackSeconds:track,hostSeconds:hostSeconds,observedHostSeconds:now,mode:mode,direction:direction))
            if let bracketSeconds { brackets.append(bracketSeconds*1000) }
        } catch { finish(reason:error as? TrialError ?? .invalidClock) }
    }
    func invalidate(_ reason: TrialError) { finish(reason:reason) }
    func finish(reason: TrialError? = nil) {
        guard active else { return }
        session.finish(reason:reason ?? .cancelled); finalize(reason:session.invalidation)
    }
    private func finalize(reason: TrialError?) {
        timer?.invalidate(); timer=nil; audio.stop()
        UIApplication.shared.isIdleTimerDisabled=savedIdleDisabled
        guard let challenge else { return }
        let assessment=Assessor.assess(events:events,map:challenge.map,invalidations:reason.map { [$0] } ?? [])
        if let key {
            let trial=SavedTrial(date:now(),key:key,assessment:assessment,completed:reason == nil && session.progress == 1,training:attemptAssociation)
            persist(trial)
            saveDiagnostics(trial)
        }
        screen="result"
    }
    func comparison(for trial: SavedTrial) -> LandingComparison {
        LandingComparison(trial:trial,history:pendingSave ?? history,historyAvailable:historyWritable)
    }
    /// Retain ordinary failed saves in effective history. Unknown initial history stays unknown.
    func persist(_ trial: SavedTrial) {
        result=trial
        guard historyWritable else { return }
        var updated=pendingSave ?? history; updated.append(trial)
        if let trainingRunID {
            let accepted=updated.training.accept(trial,runID:trainingRunID)
            if !accepted {
                errorMessage=trial.trainingEligible
                    ? "This attempt used different conditions. It is saved separately. Resume with the earlier conditions, or restart this session from Home."
                    : "This attempt is saved, but doesn’t advance training. Retry this step without outside timing help; keep playing until the song ends."
            }
        }
        pendingSave=updated
        retrySave()
    }
    func retrySave() {
        guard historyWritable, let pendingSave else { return }
        do { try store.save(pendingSave); history=pendingSave; self.pendingSave=nil; storageMessage=nil }
        catch { storageMessage="This result hasn’t been saved. Free some space, then tap Save again. Your earlier history is safe." }
    }
    var canRetrySave: Bool { pendingSave != nil }

    var contentIdentity: TrainingContent { TrainingContent(benchmark:ContentRevision.catalogSHA256,training:TrainingContentRevision.catalogSHA256) }
    var attemptAssociation: TrainingAttempt? {
        guard let run=currentTrainingRun, !run.complete else { return nil }
        return TrainingAttempt(runID:run.id,step:run.trialIDs.count)
    }
    var currentTrainingRun: TrainingRun? {
        guard let trainingRunID else { return nil }
        return history.training.runs.first { $0.id == trainingRunID }
    }
    var trainingActionTitle: String {
        if let run=history.training.active(mode:mode) { return "Resume \(run.kind.rawValue) · \(run.trialIDs.count+1) of \(run.challenges.count)" }
        var state=history.training
        switch state.due(mode:mode,day:state.day(at:now())) {
        case .baseline: return "Establish your baseline"
        case .daily: return "Start today’s session · about 4 minutes"
        case .checkpoint: return "Retest your benchmark"
        case .transfer: return "Try the separate-song transfer"
        case nil: return "Today’s session is complete"
        }
    }
    var trainingAvailable: Bool {
        guard historyWritable, pendingSave == nil else { return false }
        var state=history.training
        return state.due(mode:mode,day:state.day(at:now())) != nil
    }
    var reliableGap: String? {
        let ids=Set(history.training.runs.filter { $0.mode == mode && $0.complete }.flatMap(\.trialIDs))
        let gaps=history.trials.filter { ids.contains($0.id) && $0.key.content == contentIdentity.revision(for:$0.key.challenge) && ($0.reward?.stars ?? 0) >= 2 }.compactMap { trial in
            catalog?.challenges.first { $0.id == trial.key.challenge }?.gapSeconds
        }
        guard let longest=gaps.max() else { return nil }
        return "Longest training gap held at two-star tolerances: \(String(format:"%.1f",longest)) seconds (including the fade)."
    }
    var chapter: String {
        ["Finding the pulse","Holding longer","Carrying the quiet","Leaving room"][history.training.earnedLevel(mode:mode,trials:history.trials,content:contentIdentity)]
    }
    func beginTraining() {
        guard !active, trainingAvailable else { return }
        var updated=history
        guard let run=updated.training.begin(mode:mode,date:now(),trials:updated.trials,content:contentIdentity) else { return }
        do {
            try store.save(updated); history=updated; trainingRunID=run.id
            if let id=run.nextChallenge, let i=catalog?.challenges.firstIndex(where: { $0.id == id }) { choose(i,training:true) }
        } catch { storageMessage="The session couldn’t be saved. Free some space and try again. Training hasn’t started." }
    }
    func continueTraining() {
        guard !active, pendingSave == nil, let run=currentTrainingRun else { return }
        if let id=run.nextChallenge, let i=catalog?.challenges.firstIndex(where: { $0.id == id }) { choose(i,training:true) }
        else { home() }
    }
    func restartTraining() {
        guard !active, pendingSave == nil, historyWritable else { return }
        var updated=history; updated.training.abandon(mode:mode)
        do { try store.save(updated); history=updated; trainingRunID=nil; beginTraining() }
        catch { storageMessage="Couldn’t restart the session. Your existing progress is preserved." }
    }
    func summary(for run: TrainingRun) -> String {
        guard run.complete else { return "\(run.trialIDs.count) of \(run.challenges.count) verified steps saved. You can leave and resume here." }
        if run.kind == .daily { return "Session complete. Come back on another day for more practice. After three practice days, you’ll repeat the benchmark and try a separate song." }
        guard let summary=TrainingSummary(run:run,trials:history.trials) else { return "No compatible summary is available." }
        let reference=history.training.runs.first { $0.mode == run.mode && $0.complete && $0.kind == (run.kind == .transfer ? .transfer : .baseline) }
        if let reference, reference.id != run.id, let baseline=TrainingSummary(run:reference,trials:history.trials) {
            if let change=summary.change(from:baseline) { return change }
            return "This retest used different conditions from your baseline. Its results are saved separately; no improvement comparison is available."
        }
        return "Three-trial \(run.kind == .transfer ? "transfer reference" : "baseline") saved: median landing error \(String(format:"%.1f",summary.landing)) ms, consistency variation \(String(format:"%.1f",summary.consistency)) ms, drift magnitude \(String(format:"%.1f",summary.drift)) ms per pulse. \(run.kind == .transfer ? "Later tests of this song will compare here. A different song alone doesn’t prove general improvement." : "Later checkpoints repeat this exact challenge. Lower errors are better.")"
    }


    #if DEBUG && targetEnvironment(simulator)
    /// Isolated UI navigation fixture. No physical builds, live audio, or real-history writes.
    private func completeUIFixture(_ challenge: Challenge) {
        let map=challenge.map
        let captured=map.beats.indices.map { i -> InputEvent in
            let landing=currentTrainingRun?.kind == .baseline ? 0.08 : 0.02
            let time=map.seconds(i)+0.04+(i >= map.gapStartBeat ? landing : 0)
            return InputEvent(trackSeconds:time,hostSeconds:100+time,observedHostSeconds:100+time+0.01,mode:mode,direction:mode == .strum ? .down : nil)
        }
        let key=ComparisonKey(content:challenge.song == nil ? ContentRevision.catalogSHA256 : TrainingContentRevision.catalogSHA256,challenge:challenge.id,mode:mode,device:"SIMULATOR-UI-FIXTURE",system:"fixture",route:"Speaker",sampleRate:48000,bufferDuration:0.005,outputLatency:0,assistance:outsideHelp ? "outside-timing-help" : "direct-touch")
        persist(SavedTrial(date:now(),key:key,assessment:Assessor.assess(events:captured,map:map),completed:true,training:attemptAssociation))
        screen="result"
    }
    func advanceFixtureDay() {
        guard Self.uiFixture else { return }
        fixtureDate=Date(timeIntervalSince1970:Double((history.training.latestDay ?? Int(now().timeIntervalSince1970/86400))+1)*86400+10)
    }
    #endif

    /// Local developer evidence only. Not loaded by scoring or comparison and not synced.
    private func saveDiagnostics(_ trial: SavedTrial) {
        struct Diagnostic: Encodable {
            let trial: SavedTrial
            let events: [InputEvent]
            let crossingBracketsMS: [Double]
            let anchorCount: Int
            let maximumClockResidualMS: Double
        }
        let folder=store.url.deletingLastPathComponent().appendingPathComponent("Diagnostics",isDirectory:true)
        do {
            try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
            let payload=Diagnostic(trial:trial,events:events,crossingBracketsMS:brackets,anchorCount:audio.anchorCount,maximumClockResidualMS:audio.maximumClockResidualMS)
            try JSONEncoder().encode(payload).write(to:folder.appendingPathComponent("\(trial.id).json"),options:.atomic)
        } catch { /* Diagnostic loss never changes the player result or history-save status. */ }
    }
}

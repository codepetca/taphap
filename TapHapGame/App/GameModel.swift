import AVFAudio
import SwiftUI
import UIKit

@MainActor
final class GameModel: ObservableObject {
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

    init(store: HistoryStore? = nil) {
        let folder=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("TapHap",isDirectory:true)
        self.store=store ?? HistoryStore(url:folder.appendingPathComponent("history.json"))
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
    func choose(_ index: Int) {
        guard !active, catalog?.challenges.indices.contains(index) == true else { return }
        selection=index; screen="play"; result=nil; session=ChallengeSession(); errorMessage=nil
    }
    func home() { guard !active else { return }; screen="selection"; result=nil }
    func retry() { choose(selection) }
    func next() { guard let catalog else { return }; choose((selection+1)%catalog.challenges.count) }
    func environmentChanged(_ notification: Notification.Name, reason: TrialError) {
        if active { finish(reason:reason) }
        if notification == AVAudioSession.mediaServicesWereResetNotification { audio.rebuildAfterMediaServicesReset() }
    }
    func start(deferArming: (@escaping @MainActor @Sendable () -> Void) -> Void = { action in DispatchQueue.main.async { action() } }) {
        guard !active, screen == "play", let challenge else { return }
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
            key=ComparisonKey(content:ContentRevision.catalogSHA256,challenge:challenge.id,mode:mode,device:device,
                              system:UIDevice.current.systemVersion,route:route.currentRoute.outputs[0].portType.rawValue,
                              sampleRate:route.sampleRate,bufferDuration:route.ioBufferDuration,outputLatency:route.outputLatency,
                              assistance:UIAccessibility.isVoiceOverRunning ? "direct-touch-voiceover" : "direct-touch")
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
            let trial=SavedTrial(key:key,assessment:assessment,completed:reason == nil && session.progress == 1)
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
        pendingSave=updated
        retrySave()
    }
    func retrySave() {
        guard historyWritable, let pendingSave else { return }
        do { try store.save(pendingSave); history=pendingSave; self.pendingSave=nil; storageMessage=nil }
        catch { storageMessage="This result hasn’t been saved. Free some space, then tap Save again. Your earlier history is safe." }
    }
    var canRetrySave: Bool { pendingSave != nil }
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

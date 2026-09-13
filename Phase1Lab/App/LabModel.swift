import AVFAudio
import SwiftUI
import UIKit

struct TrialRecord: Codable {
    let schema: Int
    let wallClockRecordedAt: Date // provenance only; never used to score
    let mode: InputMode
    let route: [String:String]
    let scheduledHostSeconds: Double
    let events: [InputEvent]
    let anchors: [AudioAnchor]
    let crossingBracketsMS: [Double]
    let invalidations: [TrialError]
    let score: TrialScore?
    let assessment: TrialAssessment
    let anchorCount: Int
    let maximumClockResidualMS: Double
    let acousticObservation: String
}

@MainActor
final class LabModel: ObservableObject {
    @Published var mode: InputMode = .tap
    @Published var running = false
    @Published var status = "Engineering lab. Listen for the pulse, then continue through silence."
    @Published var progress = 0.0
    let audio = LabAudioPlayer()
    private(set) var lastAssessment: TrialAssessment?
    private var events: [InputEvent] = []
    private var anchors: [AudioAnchor] = []
    private var crossingBracketsMS: [Double] = []
    private var invalidations: [TrialError] = []
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []
    @Published private(set) var starting = false
    private var startGeneration = 0
    private var startObservationHost = 0.0

    init() {
        let center = NotificationCenter.default
        for (notification,reason) in [(AVAudioSession.routeChangeNotification,TrialError.routeChanged),
                                       (AVAudioSession.interruptionNotification,.interruption),
                                       (AVAudioSession.mediaServicesWereResetNotification,.discontinuity),
                                       (NSNotification.Name.AVAudioEngineConfigurationChange,.discontinuity),
                                       (UIApplication.willResignActiveNotification,.backgrounded)] {
            observers.append(center.addObserver(forName:notification,object:nil,queue:.main) { [weak self] _ in
                MainActor.assumeIsolated { self?.handleEnvironmentChange(notification, reason:reason) }
            })
        }
    }
    func handleEnvironmentChange(_ notification: Notification.Name, reason: TrialError) {
        if running || starting { invalidate(reason) }
        if notification == AVAudioSession.mediaServicesWereResetNotification { audio.rebuildAfterMediaServicesReset() }
    }
    func start(deferArming: (@escaping () -> Void) -> Void = { DispatchQueue.main.async(execute:$0) }) {
        guard !running, !starting else { return }
        starting = true
        startGeneration += 1
        let generation = startGeneration
        lastAssessment = nil
        events = []; anchors = []; crossingBracketsMS = []; invalidations = []; progress = 0
        do {
            try audio.start()
            guard starting, generation == startGeneration else { audio.stop(); return }
            startObservationHost = LabAudioPlayer.hostNow()
            status = "Keep the same pulse through the silence."
            // Any environmental invalidation during preparation cancels this generation.
            deferArming { [weak self] in
                guard let self, self.starting, generation == self.startGeneration else { return }
                guard UIApplication.shared.applicationState == .active else { self.invalidate(.backgrounded); return }
                self.running = true; self.starting = false
                self.timer = Timer.scheduledTimer(withTimeInterval:0.05,repeats:true) { [weak self] _ in
                    MainActor.assumeIsolated { self?.observe() }
                }
            }
        } catch { starting = false; audio.stop(); status = "Start failed: \(error)" }
    }
    func observe() {
        guard running else { return }
        do {
            guard let anchor = try audio.anchor() else {
                if LabAudioPlayer.hostNow()-startObservationHost > 1 { invalidate(.invalidClock) }
                return
            }
            let now = LabAudioPlayer.hostNow()
            guard abs(now-anchor.hostSeconds) < 0.25 else { invalidate(.staleClock); return }
            anchors.append(anchor)
            progress = min(1,max(0,anchor.sample/Double(audio.map.frameCount)))
            if anchor.sample >= Double(audio.map.frameCount) { finish() }
        } catch { invalidate(error as? TrialError ?? .invalidClock) }
    }
    func capture(hostSeconds: Double, direction: StrokeDirection?, bracketSeconds: Double? = nil) {
        guard running else { return }
        do {
            let now = LabAudioPlayer.hostNow()
            guard let anchor = try audio.anchor() else { throw TrialError.invalidClock }
            let track = try anchor.trackSeconds(touchHostSeconds:hostSeconds,observedHostSeconds:now)
            guard track >= 0, track < Double(audio.map.frameCount)/audio.map.sampleRate else { return }
            events.append(InputEvent(trackSeconds:track,hostSeconds:hostSeconds,observedHostSeconds:now,mode:mode,direction:direction))
            if let bracketSeconds { crossingBracketsMS.append(bracketSeconds*1000) }
        } catch { invalidate(error as? TrialError ?? .invalidClock) }
    }
    func invalidate(_ reason: TrialError) {
        guard running || starting else { return }
        invalidations.append(reason); finish()
    }
    func finish() {
        guard running || starting else { return }
        starting = false; startGeneration += 1
        running = false; timer?.invalidate(); timer = nil
        let assessment: TrialAssessment
        if let map = audio.map { assessment = Assessor.assess(events:events,map:map,invalidations:invalidations) }
        else { assessment = .invalid(invalidations.first ?? .invalidClock) }
        lastAssessment = assessment
        let record = TrialRecord(schema:2,wallClockRecordedAt:Date(),mode:mode,route:audio.route,
                                 scheduledHostSeconds:audio.scheduledHostSeconds,events:events,anchors:anchors,
                                 crossingBracketsMS:crossingBracketsMS,invalidations:invalidations,score:assessment.score,assessment:assessment,
                                 anchorCount:audio.anchorCount,maximumClockResidualMS:audio.maximumClockResidualMS,
                                 acousticObservation:"unobserved; render progression is not an acoustic pass")
        audio.stop()
        do {
            let folder = FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0].appendingPathComponent("Phase1Trials")
            try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted,.sortedKeys]; encoder.dateEncodingStrategy = .iso8601
            let file = folder.appendingPathComponent("trial-\(UUID().uuidString).json")
            try encoder.encode(record).write(to:file,options:.atomic)
            status = assessment.summary + " Diagnostic saved locally."
            print("PHASE1_RECORD \(file.lastPathComponent) anchors=\(record.anchorCount) inputs=\(events.count) invalid=\(invalidations.map(\.rawValue))")
        } catch { status = "Could not save trial: \(error)" }
    }
}

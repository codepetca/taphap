import Foundation
import MusicKit

enum LabAudioSource: String, CaseIterable, Identifiable {
    case reference = "Reference click"
    case appleMusic = "Apple Music"

    var id: Self { self }
}

@MainActor
final class LabViewModel: ObservableObject {
    @Published private(set) var session = TrainingSession()
    @Published private(set) var source: LabAudioSource = .reference
    @Published private(set) var statusMessage = "Start the 120 BPM reference click."
    @Published private(set) var referenceGrid: ReferenceGrid?
    @Published private(set) var knownGridDiagnostics: KnownGridDiagnostics?
    @Published private(set) var routeSnapshot: AudioRouteSnapshot?
    @Published private(set) var muteStartProbe: MuteBoundaryProbe?
    @Published private(set) var muteEndProbe: MuteBoundaryProbe?
    @Published private(set) var musicPauseProbe: MusicTransportProbe?
    @Published private(set) var musicResumeProbe: MusicTransportProbe?
    @Published private(set) var musicPlayheadAdvance: TimeInterval?
    @Published private(set) var musicPlayheadError: TimeInterval?
    @Published private(set) var eventLog: [String] = []

    let appleMusic = AppleMusicController()

    private let audioSession = AudioSessionMuteController()
    private let referencePlayer = ReferenceClickPlayer()
    private let gapScheduler = GapScheduler()
    private var musicTimeAtMute: TimeInterval?

    init() {
        audioSession.onMuteStateChange = { [weak self] isMuted, observedAt in
            DispatchQueue.main.async { [weak self] in
                self?.log(String(
                    format: "Output-mute notification: %@ at %.3f",
                    isMuted ? "muted" : "unmuted",
                    observedAt
                ))
            }
        }
    }

    var phase: TrainingPhase { session.phase }
    var pulse: PulseEstimate? { session.pulse }
    var result: GapScore? { session.result }
    var canTap: Bool { session.phase != .idle && session.phase != .result }

    func selectSource(_ newSource: LabAudioSource) {
        guard newSource != source else { return }
        stopEverything()
        source = newSource
        statusMessage = newSource == .reference
            ? "Start the 120 BPM reference click."
            : appleMusic.message
    }

    func startReference() {
        stopEverything()
        do {
            try audioSession.prepareForPlayback()
            referenceGrid = try referencePlayer.start()
            routeSnapshot = audioSession.routeSnapshot()
            session.begin()
            statusMessage = "Tap with the click until the estimate becomes ready."
            log("Reference click started at 120 BPM")
            logRoute()
        } catch {
            statusMessage = "Reference audio failed: \(error.localizedDescription)"
            log(statusMessage)
        }
    }

    func playAppleMusic(_ song: Song) async {
        stopEverything()
        source = .appleMusic
        do {
            try audioSession.prepareForPlayback()
            try await appleMusic.play(song)
            routeSnapshot = audioSession.routeSnapshot()
            session.begin()
            statusMessage = "Tap with the song until the estimate becomes ready."
            log("Apple Music playback started: \(song.title) — \(song.artistName)")
            logRoute()
        } catch {
            statusMessage = "Apple Music playback failed: \(error.localizedDescription)"
            log(statusMessage)
        }
    }

    func recordTap(at timestamp: TimeInterval) {
        guard canTap else { return }
        session.recordTap(at: timestamp)

        if session.phase == .calibrating {
            if let grid = referenceGrid {
                knownGridDiagnostics = KnownGridDiagnostics.measure(
                    timestamps: session.audibleTaps,
                    anchor: grid.anchor,
                    period: grid.period
                )
            }
            if session.pulse != nil {
                statusMessage = "Baseline ready. Keep tapping or start the silent gap."
            } else if session.audibleTaps.count >= 8 {
                statusMessage = "Keep tapping steadily—the pulse estimate is not stable yet."
            } else {
                statusMessage = "Keep tapping… \(8 - session.audibleTaps.count) more needed."
            }
        }
    }

    func startGap() {
        guard let plan = session.prepareGap(now: MonotonicClock.now) else { return }
        statusMessage = "Silence is about to start. Keep tapping."
        muteStartProbe = nil
        muteEndProbe = nil
        musicPauseProbe = nil
        musicResumeProbe = nil
        musicTimeAtMute = nil
        musicPlayheadAdvance = nil
        musicPlayheadError = nil

        log(String(format: "Gap armed: %.3f s, %d beat intervals", plan.duration, plan.beatCount))
        let gapSource = source
        gapScheduler.schedule(
            plan: plan,
            onStart: { [weak self] targetTime in
                guard let self else { return }
                if gapSource == .appleMusic {
                    DispatchQueue.main.async { [weak self] in
                        self?.handleMusicGapStart(targetTime: targetTime)
                    }
                } else {
                    let probe = self.audioSession.setMuted(true, targetTime: targetTime)
                    DispatchQueue.main.async { [weak self] in
                        self?.handleGapStart(probe)
                    }
                }
            },
            onEnd: { [weak self] targetTime in
                guard let self else { return }
                if gapSource == .appleMusic {
                    Task { @MainActor [weak self] in
                        await self?.handleMusicGapEnd(targetTime: targetTime)
                    }
                } else {
                    let probe = self.audioSession.setMuted(false, targetTime: targetTime)
                    DispatchQueue.main.async { [weak self] in
                        self?.handleGapEnd(probe)
                    }
                }
            }
        )
    }

    func resetExercise() {
        gapScheduler.cancel()
        audioSession.forceUnmute()
        session.begin()
        muteStartProbe = nil
        muteEndProbe = nil
        musicPauseProbe = nil
        musicResumeProbe = nil
        musicPlayheadAdvance = nil
        musicPlayheadError = nil
        knownGridDiagnostics = nil
        statusMessage = "Tap with the audio until the estimate becomes ready."
        log("Exercise reset")
    }

    func stopEverything() {
        gapScheduler.cancel()
        audioSession.forceUnmute()
        referencePlayer.stop()
        appleMusic.stop()
        session.reset()
        referenceGrid = nil
        knownGridDiagnostics = nil
        routeSnapshot = nil
        muteStartProbe = nil
        muteEndProbe = nil
        musicPauseProbe = nil
        musicResumeProbe = nil
        musicTimeAtMute = nil
        musicPlayheadAdvance = nil
        musicPlayheadError = nil
    }

    func gapProgress(at time: TimeInterval) -> Double {
        guard session.phase == .silentGap, let plan = session.plan else { return 0 }
        return min(1, max(0, (time - plan.startTime) / plan.duration))
    }

    private func handleGapStart(_ probe: MuteBoundaryProbe) {
        muteStartProbe = probe
        session.beginGap()
        if source == .appleMusic {
            musicTimeAtMute = appleMusic.player.playbackTime
        }
        statusMessage = probe.errorDescription == nil
            ? "Audio is silent. Hold the pulse."
            : "Mute failed: \(probe.errorDescription!)"
        logProbe(probe, label: "Mute")
    }

    private func handleMusicGapStart(targetTime: TimeInterval) {
        let probe = appleMusic.pauseForGap(targetTime: targetTime)
        musicPauseProbe = probe
        musicTimeAtMute = probe.playbackTimeAfter
        session.beginGap()
        statusMessage = "Music paused. Hold the pulse while TapHap skips ahead."
        logMusicProbe(probe, label: "Music pause")
    }

    private func handleGapEnd(_ probe: MuteBoundaryProbe) {
        muteEndProbe = probe
        if source == .appleMusic, let start = musicTimeAtMute {
            let advance = appleMusic.player.playbackTime - start
            musicPlayheadAdvance = advance
            if let plan = session.plan {
                musicPlayheadError = advance - plan.duration
            }
        }

        let score = session.finishGap()
        if let score {
            statusMessage = "Audio returned: \(score.endSummary), \(score.direction)."
        } else {
            statusMessage = "Audio returned, but there were too few silent taps to score."
        }
        logProbe(probe, label: "Unmute")
        if let advance = musicPlayheadAdvance, let error = musicPlayheadError {
            log(String(format: "Music playhead advanced %.3f s (gap delta error %+.1f ms)", advance, error * 1_000))
        }
    }

    private func handleMusicGapEnd(targetTime: TimeInterval) async {
        guard let pausedAt = musicTimeAtMute, let plan = session.plan else {
            statusMessage = "Apple Music gap failed: missing the paused playhead."
            log(statusMessage)
            _ = session.finishGap()
            return
        }

        let probe = await appleMusic.seekAndResumeAfterGap(
            pausedAt: pausedAt,
            gapDuration: plan.duration,
            targetTime: targetTime
        )
        musicResumeProbe = probe
        musicPlayheadAdvance = probe.playbackTimeAfter - pausedAt
        musicPlayheadError = musicPlayheadAdvance.map { $0 - plan.duration }

        let score = session.finishGap()
        if let error = probe.errorDescription {
            statusMessage = "Apple Music resume failed: \(error)"
        } else if let score {
            statusMessage = "Music resumed after the skipped gap: \(score.endSummary), \(score.direction)."
        } else {
            statusMessage = "Music resumed, but there were too few silent taps to score."
        }

        logMusicProbe(probe, label: "Music seek/resume")
        if let advance = musicPlayheadAdvance, let error = musicPlayheadError {
            log(String(format: "Music playhead advanced %.3f s (gap delta error %+.1f ms)", advance, error * 1_000))
        }
    }

    private func logProbe(_ probe: MuteBoundaryProbe, label: String) {
        if let error = probe.errorDescription {
            log("\(label) API error: \(error)")
        } else {
            log(String(
                format: "\(label) scheduled error %+.2f ms; API call %.2f ms; state %@",
                probe.schedulingErrorMilliseconds,
                probe.callDurationMilliseconds,
                probe.reportedState ? "muted" : "unmuted"
            ))
        }
    }

    private func logMusicProbe(_ probe: MusicTransportProbe, label: String) {
        if let error = probe.errorDescription {
            log("\(label) error: \(error)")
            return
        }

        var message = String(
            format: "%@ scheduled error %+.2f ms; call %.2f ms; playhead %.3f → %.3f; status %@",
            label,
            probe.schedulingErrorMilliseconds,
            probe.callDurationMilliseconds,
            probe.playbackTimeBefore,
            probe.playbackTimeAfter,
            probe.playbackStatus
        )
        if let requestedTime = probe.requestedPlaybackTime {
            message += String(format: "; requested %.3f", requestedTime)
        }
        log(message)
    }

    private func logRoute() {
        guard let routeSnapshot else { return }
        log(String(
            format: "Route: %@; output latency %.1f ms; I/O buffer %.1f ms; %.0f Hz",
            routeSnapshot.name,
            routeSnapshot.outputLatencyMilliseconds,
            routeSnapshot.ioBufferMilliseconds,
            routeSnapshot.sampleRate
        ))
    }

    private func log(_ message: String) {
        let elapsed = MonotonicClock.now
        eventLog.insert(String(format: "%.3f  %@", elapsed, message), at: 0)
        print("TapHap Lab: \(message)")
        if eventLog.count > 40 {
            eventLog.removeLast(eventLog.count - 40)
        }
    }
}

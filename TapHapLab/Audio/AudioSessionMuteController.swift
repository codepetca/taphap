import AVFAudio

struct MuteBoundaryProbe: Equatable, Sendable {
    let requestedState: Bool
    let targetTime: TimeInterval
    let callStartedAt: TimeInterval
    let callFinishedAt: TimeInterval
    let reportedState: Bool
    let errorDescription: String?

    var schedulingErrorMilliseconds: Double {
        (callStartedAt - targetTime) * 1_000
    }

    var callDurationMilliseconds: Double {
        (callFinishedAt - callStartedAt) * 1_000
    }
}

struct AudioRouteSnapshot: Equatable, Sendable {
    let name: String
    let outputLatencyMilliseconds: Double
    let sampleRate: Double
    let ioBufferMilliseconds: Double
}

final class AudioSessionMuteController {
    private let session = AVAudioSession.sharedInstance()
    private var muteObserver: NSObjectProtocol?
    var onMuteStateChange: ((_ isMuted: Bool, _ observedAt: TimeInterval) -> Void)?

    init() {
        muteObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.outputMuteStateChangeNotification,
            object: session,
            queue: nil
        ) { [weak self] notification in
            let value = notification.userInfo?[AVAudioSession.muteStateKey] as? NSNumber
            self?.onMuteStateChange?(value?.boolValue ?? self?.session.isOutputMuted ?? false, MonotonicClock.now)
        }
    }

    deinit {
        if let muteObserver {
            NotificationCenter.default.removeObserver(muteObserver)
        }
    }

    func prepareForPlayback() throws {
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
        try session.setOutputMuted(false)
    }

    func setMuted(_ muted: Bool, targetTime: TimeInterval) -> MuteBoundaryProbe {
        let startedAt = MonotonicClock.now
        var errorDescription: String?
        do {
            try session.setOutputMuted(muted)
        } catch {
            errorDescription = error.localizedDescription
        }
        let finishedAt = MonotonicClock.now
        return MuteBoundaryProbe(
            requestedState: muted,
            targetTime: targetTime,
            callStartedAt: startedAt,
            callFinishedAt: finishedAt,
            reportedState: session.isOutputMuted,
            errorDescription: errorDescription
        )
    }

    func forceUnmute() {
        try? session.setOutputMuted(false)
    }

    func routeSnapshot() -> AudioRouteSnapshot {
        let outputs = session.currentRoute.outputs
        let name = outputs.isEmpty
            ? "No output route"
            : outputs.map { "\($0.portName) (\($0.portType.rawValue))" }.joined(separator: ", ")
        return AudioRouteSnapshot(
            name: name,
            outputLatencyMilliseconds: session.outputLatency * 1_000,
            sampleRate: session.sampleRate,
            ioBufferMilliseconds: session.ioBufferDuration * 1_000
        )
    }
}

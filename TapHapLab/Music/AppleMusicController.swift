import Foundation
import MusicKit

struct MusicTransportProbe: Equatable, Sendable {
    enum Action: String, Sendable {
        case pause
        case seekAndResume = "seek + resume"
    }

    let action: Action
    let targetTime: TimeInterval
    let callStartedAt: TimeInterval
    let callFinishedAt: TimeInterval
    let playbackTimeBefore: TimeInterval
    let requestedPlaybackTime: TimeInterval?
    let playbackTimeAfter: TimeInterval
    let playbackStatus: String
    let errorDescription: String?

    var schedulingErrorMilliseconds: Double {
        (callStartedAt - targetTime) * 1_000
    }

    var callDurationMilliseconds: Double {
        (callFinishedAt - callStartedAt) * 1_000
    }
}

@MainActor
final class AppleMusicController: ObservableObject {
    @Published private(set) var authorizationStatus = MusicAuthorization.currentStatus
    @Published private(set) var canPlayCatalogContent = false
    @Published private(set) var searchResults: [Song] = []
    @Published private(set) var selectedSong: Song?
    @Published private(set) var playbackTime: TimeInterval = 0
    @Published private(set) var isPlaying = false
    @Published private(set) var message = "Connect Apple Music to begin."

    let player = ApplicationMusicPlayer.shared
    private var pollingTask: Task<Void, Never>?

    init() {
        startPolling()
    }

    func requestAccess() async {
        authorizationStatus = await MusicAuthorization.request()
        guard authorizationStatus == .authorized else {
            canPlayCatalogContent = false
            message = "Apple Music access was not granted."
            return
        }

        do {
            let subscription = try await MusicSubscription.current
            canPlayCatalogContent = subscription.canPlayCatalogContent
            message = canPlayCatalogContent
                ? "Apple Music is ready. Search for a song."
                : "This Apple ID cannot currently play catalog songs."
        } catch {
            canPlayCatalogContent = false
            message = "Could not read the Apple Music subscription: \(error.localizedDescription)"
        }
    }

    func search(for term: String) async {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard authorizationStatus == .authorized, canPlayCatalogContent else {
            message = "Connect an Apple Music subscription before searching."
            return
        }
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }

        message = "Searching…"
        do {
            var request = MusicCatalogSearchRequest(term: trimmed, types: [Song.self])
            request.limit = 10
            let response = try await request.response()
            searchResults = Array(response.songs)
            message = searchResults.isEmpty ? "No songs found." : "Choose a full song to play."
        } catch let error as MusicDataRequest.Error {
            searchResults = []
            let diagnostic = [
                "HTTP \(error.status)",
                "code \(error.code)",
                error.title,
                error.detailText,
            ]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
            message = "Search failed: \(diagnostic)"
            print("MusicKit catalog search failed: \(diagnostic)")
        } catch {
            searchResults = []
            let diagnostic = Self.diagnosticDescription(for: error)
            message = "Search failed: \(diagnostic)"
            print("MusicKit catalog search failed: \(String(reflecting: error)); \(diagnostic)")
        }
    }

    func play(_ song: Song) async throws {
        let queue = ApplicationMusicPlayer.Queue(for: [song])
        if #available(iOS 26.4, *) {
            queue.affectsListeningHistory = false
        }
        player.queue = queue
        try await player.prepareToPlay()
        try await player.play()
        selectedSong = song
        searchResults = []
        isPlaying = true
        message = "Playing \(song.title)"
    }

    func togglePlayback() async {
        if player.state.playbackStatus == .playing {
            player.pause()
        } else {
            do {
                try await player.play()
            } catch {
                message = "Playback failed: \(error.localizedDescription)"
            }
        }
        updatePlaybackSnapshot()
    }

    func stop() {
        player.stop()
        selectedSong = nil
        playbackTime = 0
        isPlaying = false
    }

    func pauseForGap(targetTime: TimeInterval) -> MusicTransportProbe {
        let startedAt = MonotonicClock.now
        let timeBefore = player.playbackTime
        player.pause()
        let finishedAt = MonotonicClock.now

        updatePlaybackSnapshot()
        return MusicTransportProbe(
            action: .pause,
            targetTime: targetTime,
            callStartedAt: startedAt,
            callFinishedAt: finishedAt,
            playbackTimeBefore: timeBefore,
            requestedPlaybackTime: nil,
            playbackTimeAfter: player.playbackTime,
            playbackStatus: String(describing: player.state.playbackStatus),
            errorDescription: nil
        )
    }

    func seekAndResumeAfterGap(
        pausedAt: TimeInterval,
        gapDuration: TimeInterval,
        targetTime: TimeInterval
    ) async -> MusicTransportProbe {
        let startedAt = MonotonicClock.now
        let timeBefore = player.playbackTime
        let requestedTime = pausedAt.isFinite ? pausedAt + gapDuration : nil
        var errorDescription: String?

        if let requestedTime {
            player.playbackTime = requestedTime
            do {
                try await player.play()
            } catch {
                errorDescription = Self.diagnosticDescription(for: error)
            }
        } else {
            errorDescription = "MusicKit returned an invalid playhead before the gap."
        }

        let finishedAt = MonotonicClock.now
        updatePlaybackSnapshot()
        return MusicTransportProbe(
            action: .seekAndResume,
            targetTime: targetTime,
            callStartedAt: startedAt,
            callFinishedAt: finishedAt,
            playbackTimeBefore: timeBefore,
            requestedPlaybackTime: requestedTime,
            playbackTimeAfter: player.playbackTime,
            playbackStatus: String(describing: player.state.playbackStatus),
            errorDescription: errorDescription
        )
    }

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.updatePlaybackSnapshot()
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    private func updatePlaybackSnapshot() {
        playbackTime = player.playbackTime
        isPlaying = player.state.playbackStatus == .playing
    }

    private static func diagnosticDescription(for error: any Error) -> String {
        let cocoaError = error as NSError
        var parts = [
            "\(cocoaError.domain) \(cocoaError.code)",
            cocoaError.localizedDescription,
        ]

        if let underlyingError = cocoaError.userInfo[NSUnderlyingErrorKey] as? NSError {
            parts.append(
                "underlying \(underlyingError.domain) \(underlyingError.code): "
                    + underlyingError.localizedDescription
            )
        }

        return parts.joined(separator: " · ")
    }
}

import Foundation
#if SWIFT_PACKAGE
import Phase1Core
#endif

public struct Challenge: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let map: BeatMap
    public var gapSeconds: Double { map.seconds(map.returnBeat)-map.seconds(map.gapStartBeat) }
}
public struct SongCatalog: Codable, Sendable {
    public let revision: String
    public let title: String
    public let audioSHA256: String
    public let challenges: [Challenge]
    public func validate() throws {
        guard revision == "afterglow-v1", title == "Afterglow", challenges.count == 3,
              Set(challenges.map(\.id)).count == challenges.count else { throw TrialError.assetMismatch }
        for challenge in challenges { try challenge.map.validate() }
    }
}
public enum PlayStage: String, Codable, Sendable {
    case ready, preparing, playing, warning, silent, returned, result
}
/// The audio clock drives observations; this state never schedules sound.
public struct ChallengeSession: Sendable {
    public private(set) var stage: PlayStage = .ready
    public private(set) var generation = 0
    public private(set) var invalidation: TrialError?
    public private(set) var progress: Double = 0
    public init() {}
    public var active: Bool { [.preparing,.playing,.warning,.silent,.returned].contains(stage) }
    public mutating func prepare() -> Int {
        generation += 1; stage = .preparing; progress = 0; invalidation = nil
        return generation
    }
    public mutating func arm(generation token: Int) -> Bool {
        guard stage == .preparing, token == generation else { return false }
        stage = .playing; return true
    }
    public mutating func observe(sample: Double, map: BeatMap) {
        guard active, stage != .preparing else { return }
        guard sample.isFinite, sample >= progress*Double(map.frameCount) else { finish(reason:.discontinuity); return }
        progress = min(1, sample/Double(map.frameCount))
        if sample >= Double(map.frameCount) { finish(); return }
        if sample >= Double(map.beats[map.returnBeat]) { stage = .returned }
        else if sample >= Double(map.beats[map.gapStartBeat]) { stage = .silent }
        else if sample >= Double(map.beats[map.gapStartBeat])-map.sampleRate*2.3 { stage = .warning }
        else { stage = .playing }
    }
    public mutating func finish(reason: TrialError? = nil) {
        guard active else { return }
        invalidation = reason; stage = .result; generation += 1
    }
}

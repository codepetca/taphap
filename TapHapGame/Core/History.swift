import Foundation
#if SWIFT_PACKAGE
import Phase1Core
#endif

/// Equality is intentionally strict: no cross-device, route, mode, map or assistance claims.
public struct ComparisonKey: Codable, Equatable, Sendable {
    public let content: String
    public let challenge: String
    public let mode: InputMode
    public let device: String
    public let system: String
    public let route: String
    public let sampleRate: Double
    public let bufferDuration: Double
    public let outputLatency: Double
    public let assistance: String
    public let scoringVersion: Int
    public init(content: String, challenge: String, mode: InputMode, device: String, system: String,
                route: String, sampleRate: Double, bufferDuration: Double, outputLatency: Double, assistance: String) {
        self.content=content; self.challenge=challenge; self.mode=mode; self.device=device; self.system=system
        self.route=route; self.sampleRate=sampleRate; self.bufferDuration=bufferDuration
        self.outputLatency=outputLatency; self.assistance=assistance; scoringVersion=1
    }
    public var validatedRoute: Bool { route == "Speaker" }
}
public struct SavedTrial: Codable, Identifiable, Sendable {
    public let id: UUID
    public let date: Date
    public let key: ComparisonKey
    public let assessment: TrialAssessment
    public let completed: Bool
    public let training: TrainingAttempt?
    public init(id: UUID = UUID(), date: Date = Date(), key: ComparisonKey, assessment: TrialAssessment, completed: Bool, training: TrainingAttempt? = nil) {
        self.id=id; self.date=date; self.key=key; self.assessment=assessment; self.completed=completed; self.training=training
    }
    /// Personal best is explicitly closest landing, not an invented composite grade.
    public var landingMagnitude: Double? {
        guard completed, key.validatedRoute, key.assistance == "direct-touch", assessment.kind == .scored,
              assessment.invalidation == nil, assessment.scoreIssue == nil, let score=assessment.score,
              score.reentryMS.isFinite else { return nil }
        return abs(score.reentryMS)
    }
}
public struct TrialHistory: Codable, Sendable {
    public var schema = 2
    public var training = TrainingState()
    public private(set) var trials: [SavedTrial] = []
    public init() {}
    enum CodingKeys: String, CodingKey { case schema, trials, training }
    public init(from decoder: Decoder) throws {
        let c=try decoder.container(keyedBy:CodingKeys.self)
        let version=try c.decode(Int.self,forKey:.schema)
        guard version == 1 || version == 2 else { throw HistoryError.unsupportedSchema }
        trials=try c.decode([SavedTrial].self,forKey:.trials)
        guard Set(trials.map(\.id)).count == trials.count else { throw HistoryError.unreadable }
        training = version == 1 ? TrainingState() : try c.decode(TrainingState.self,forKey:.training)
        schema=2
        try validate()
    }
    public func validate() throws {
        guard schema == 2, Set(trials.map(\.id)).count == trials.count,
              Set(training.runs.map(\.id)).count == training.runs.count else { throw HistoryError.unreadable }
        if let latest=training.latestDay {
            guard (-719000...2900000).contains(latest), latest >= (training.runs.map(\.day).max() ?? latest) else { throw HistoryError.unreadable }
        } else if !training.runs.isEmpty { throw HistoryError.unreadable }
        var consumed=Set<UUID>(), replay=TrainingState()
        var priorDay: Int?
        for run in training.runs {
            guard (-719000...2900000).contains(run.day), run.day >= (priorDay ?? run.day),
                  !run.content.benchmark.isEmpty, !run.content.training.isEmpty,
                  !(run.complete && run.abandoned), !run.challenges.isEmpty,
                  run.trialIDs.count <= run.challenges.count,
                  replay.active(mode:run.mode) == nil,
                  let expected=replay.begin(mode:run.mode,date:Date(timeIntervalSince1970:Double(run.day)*86400+10),trials:trials,content:run.content),
                  expected.kind == run.kind, expected.challenges == run.challenges else { throw HistoryError.unreadable }
            priorDay=run.day
            for (index,id) in run.trialIDs.enumerated() {
                guard consumed.insert(id).inserted, let trial=trials.first(where: { $0.id == id }),
                      trial.training == TrainingAttempt(runID:run.id,step:index),
                      trial.key.content == run.content.revision(for:trial.key.challenge),
                      trial.trainingEligible, trial.key.mode == run.mode,
                      trial.key.challenge == run.challenges[index], let condition=run.condition,
                      trial.key.sameEnvironment(as:condition),
                      run.kind == .daily || trial.key == condition else { throw HistoryError.unreadable }
            }
            guard run.condition == run.trialIDs.first.flatMap({ id in trials.first { $0.id == id }?.key }) else { throw HistoryError.unreadable }
            // Replay stores final evidence only after the original plan has been recomputed.
            replay.runs[replay.runs.count-1]=run
        }
    }
    public mutating func append(_ trial: SavedTrial) {
        guard !trials.contains(where: { $0.id == trial.id }) else { return }
        trials.append(trial)
    }
    public func compatible(with trial: SavedTrial) -> [SavedTrial] {
        trials.filter { $0.id != trial.id && $0.key == trial.key && $0.landingMagnitude != nil }
    }
    public func previous(with trial: SavedTrial) -> SavedTrial? { compatible(with:trial).last }
    public func best(with trial: SavedTrial) -> SavedTrial? {
        compatible(with:trial).min { $0.landingMagnitude! < $1.landingMagnitude! }
    }
}
public enum HistoryError: Error { case unreadable, unsupportedSchema }
public struct HistoryStore: Sendable {
    public let url: URL
    public init(url: URL) { self.url=url }
    public func load() throws -> TrialHistory {
        guard FileManager.default.fileExists(atPath:url.path) else { return TrialHistory() }
        let history: TrialHistory
        do { history = try JSONDecoder().decode(TrialHistory.self,from:Data(contentsOf:url)) }
        catch { throw HistoryError.unreadable }
        guard history.schema == 2 else { throw HistoryError.unsupportedSchema }
        return history
    }
    public func save(_ history: TrialHistory) throws {
        try history.validate()
        try FileManager.default.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true)
        try JSONEncoder().encode(history).write(to:url,options:.atomic)
    }
}

/// Comparison statements require a known history, even if this attempt itself is valid.
public struct LandingComparison: Equatable, Sendable {
    public let headline: String?
    public let previous: String?
    public init(trial: SavedTrial, history: TrialHistory, historyAvailable: Bool) {
        guard let magnitude=trial.landingMagnitude else { headline=nil; previous=nil; return }
        guard historyAvailable else {
            headline="Earlier results couldn’t be read. Personal-best comparisons are unavailable."
            previous=nil; return
        }
        if let best=history.best(with:trial), let bestMagnitude=best.landingMagnitude {
            headline = magnitude < bestMagnitude
                ? "New closest landing for this challenge."
                : "Closest compatible landing: \(String(format:"%.0f",bestMagnitude)) ms from your opening pulse."
        } else { headline="Your first verified landing in these conditions." }
        if let prior=history.previous(with:trial), let last=prior.landingMagnitude {
            previous="Previous compatible attempt: \(String(format:"%.0f",last)) ms from your opening pulse."
        } else { previous=nil }
    }
}

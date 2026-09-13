import Foundation
#if SWIFT_PACKAGE
import Phase1Core
#endif

public struct TrainingContent: Codable, Equatable, Sendable {
    public let benchmark: String
    public let training: String
    public init(benchmark: String, training: String) { self.benchmark=benchmark; self.training=training }
    public func revision(for challenge: String) -> String {
        ["first-light","stay-a-little","into-the-blue"].contains(challenge) ? benchmark : training
    }
}
public struct TrainingAttempt: Codable, Equatable, Sendable {
    public let runID: UUID
    public let step: Int
    public init(runID: UUID, step: Int) { self.runID=runID; self.step=step }
}
public enum TrainingKind: String, Codable, Sendable { case baseline, daily, checkpoint, transfer }
public struct TrainingRun: Codable, Identifiable, Sendable {
    public let id: UUID
    public let kind: TrainingKind
    public let mode: InputMode
    public let day: Int
    public let challenges: [String]
    public let content: TrainingContent
    public var trialIDs: [UUID] = []
    public var condition: ComparisonKey?
    public var abandoned = false
    public var complete: Bool { trialIDs.count == challenges.count }
    public var nextChallenge: String? { complete ? nil : challenges[trialIDs.count] }
    public init(kind: TrainingKind, mode: InputMode, day: Int, challenges: [String], content: TrainingContent) {
        id=UUID(); self.kind=kind; self.mode=mode; self.day=day; self.challenges=challenges; self.content=content
    }
}
public struct TrainingState: Codable, Sendable {
    public var runs: [TrainingRun] = []
    public var latestDay: Int?
    public init() {}
    /// Fixed UTC buckets survive timezone changes. Backward clock travel cannot reopen a day.
    public mutating func day(at date: Date) -> Int {
        let raw=Int(floor(date.timeIntervalSince1970/86400))
        let day=max(raw,latestDay ?? raw); latestDay=day; return day
    }
    public func active(mode: InputMode) -> TrainingRun? { runs.last { $0.mode == mode && !$0.complete && !$0.abandoned } }
    public mutating func abandon(mode: InputMode) {
        if let i=runs.lastIndex(where: { $0.mode == mode && !$0.complete && !$0.abandoned }) { runs[i].abandoned=true }
    }
    public func baseline(mode: InputMode) -> TrainingRun? { runs.first { $0.mode == mode && $0.kind == .baseline && $0.complete } }
    public func due(mode: InputMode, day: Int) -> TrainingKind? {
        if let active=active(mode:mode) { return active.kind }
        guard let baseline=baseline(mode:mode) else { return .baseline }
        let completed=runs.filter { $0.mode == mode && $0.complete }
        if let checkpoint=completed.last(where: { $0.kind == .checkpoint }),
           !completed.contains(where: { $0.kind == .transfer && $0.day >= checkpoint.day }) { return .transfer }
        let lastCheck=completed.last(where: { $0.kind == .checkpoint })?.day ?? baseline.day
        if day > (completed.filter { $0.kind == .daily }.map(\.day).max() ?? lastCheck), day > lastCheck, Set(completed.filter { $0.kind == .daily && $0.day > lastCheck }.map(\.day)).count >= 3 { return .checkpoint }
        return completed.contains(where: { $0.kind == .daily && $0.day == day }) ? nil : .daily
    }
    public mutating func begin(mode: InputMode, date: Date, trials: [SavedTrial], content: TrainingContent) -> TrainingRun? {
        let today=day(at:date)
        if let current=active(mode:mode) { return current }
        guard let kind=due(mode:mode,day:today) else { return nil }
        let level=earnedLevel(mode:mode,trials:trials,content:content)
        let placement=today.isMultiple(of:2) ? 0 : 1
        let plan: [String]
        switch kind {
        case .baseline,.checkpoint: plan=Array(repeating:"first-light",count:3)
        case .transfer: plan=Array(repeating:"transfer-paperkite",count:3)
        case .daily:
            // All four tracks play to their authored ending: about 3m45s–4m02s.
            let weaker=personalizedLevel(mode:mode,trials:trials,ceiling:level,content:content)
            let progressiveSong=level == 0 ? "tidepool" : "lantern"
            plan=["first-light","tidepool-l\(max(0,level-1))-p\(placement)","\(progressiveSong)-l\(level)-p\(placement)","tidepool-l\(weaker)-p\(1-placement)"]
        }
        let run=TrainingRun(kind:kind,mode:mode,day:today,challenges:plan,content:content); runs.append(run); return run
    }
    /// Consume once, only the next planned challenge. A changed environment cannot mix a retest.
    public mutating func accept(_ trial: SavedTrial, runID: UUID) -> Bool {
        guard let index=runs.firstIndex(where: { $0.id == runID }), !runs[index].complete, !runs[index].abandoned,
              trial.training == TrainingAttempt(runID:runID,step:runs[index].trialIDs.count),
              trial.key.content == runs[index].content.revision(for:trial.key.challenge),
              trial.trainingEligible, trial.key.mode == runs[index].mode,
              trial.key.challenge == runs[index].nextChallenge,
              !runs.contains(where: { $0.trialIDs.contains(trial.id) }) else { return false }
        if let condition=runs[index].condition {
            guard trial.key.sameEnvironment(as:condition),
                  runs[index].kind == .daily || trial.key == condition else { return false }
        } else { runs[index].condition=trial.key }
        runs[index].trialIDs.append(trial.id); return true
    }
    public func earnedLevel(mode: InputMode, trials: [SavedTrial], content: TrainingContent) -> Int {
        var level=0
        for target in 0..<3 {
            let ids=Set(runs.filter { $0.mode == mode && $0.kind == .daily && $0.complete }.flatMap(\.trialIDs))
            let passes=trials.filter { ids.contains($0.id) && $0.key.content == content.revision(for:$0.key.challenge) && $0.key.challenge.contains("-l\(target)-") && ($0.reward?.stars ?? 0) >= 2 }
            // Two demonstrated passes on distinct training days; opening an app earns nothing.
            let demonstrated=passes.contains { reference in
                let compatible=passes.filter { $0.key.sameEnvironment(as:reference.key) && $0.key.content == reference.key.content }
                let days=Set(runs.filter { run in compatible.contains(where: { run.trialIDs.contains($0.id) }) }.map(\.day))
                return days.count >= 2
            }
            guard demonstrated else { break }; level=target+1
        }
        return level
    }
    private func personalizedLevel(mode: InputMode, trials: [SavedTrial], ceiling: Int, content: TrainingContent) -> Int {
        let ids=Set(runs.filter { $0.mode == mode && $0.kind == .daily }.flatMap(\.trialIDs))
        let recent=trials.last { ids.contains($0.id) && $0.key.content == content.revision(for:$0.key.challenge) && $0.trainingEligible }
        return (recent?.reward?.stars ?? 0) < 2 ? max(0,ceiling-1) : ceiling
    }
}
public extension ComparisonKey {
    func sameEnvironment(as other: ComparisonKey) -> Bool {
        mode == other.mode && device == other.device && system == other.system && route == other.route && sampleRate == other.sampleRate && bufferDuration == other.bufferDuration && outputLatency == other.outputLatency && assistance == other.assistance && scoringVersion == other.scoringVersion
    }
}
public struct SkillReward: Equatable, Sendable {
    public let stars: Int
    public let grade: String
    public let perfectLanding: Bool
}
public extension SavedTrial {
    var trainingEligible: Bool {
        guard landingMagnitude != nil, key.assistance == "direct-touch", let s=assessment.score else { return false }
        return [s.consistencyMS,s.tempoDriftMSPerBeat,s.reentryMS,s.baselinePeriodMS].allSatisfy(\.isFinite) && s.consistencyMS >= 0 && s.baselinePeriodMS > 0
    }
    var reward: SkillReward? {
        guard trainingEligible, let s=assessment.score else { return nil }
        let landing=abs(s.reentryMS), drift=abs(s.tempoDriftMSPerBeat)
        let stars = landing <= 25 && drift <= 2 && s.consistencyMS <= 12 ? 3 : landing <= 60 && drift <= 5 && s.consistencyMS <= 25 ? 2 : landing <= 120 && drift <= 10 && s.consistencyMS <= 40 ? 1 : 0
        return SkillReward(stars:stars,grade:["Keep practicing","C","B","A"][stars],perfectLanding:stars == 3)
    }
}
public struct TrainingSummary: Sendable {
    public let key: ComparisonKey
    public let landing: Double
    public let consistency: Double
    public let drift: Double
    public init?(run: TrainingRun, trials: [SavedTrial]) {
        guard run.complete, run.kind != .daily, run.trialIDs.count == 3,
              Set(run.trialIDs).count == 3 else { return nil }
        let values=run.trialIDs.compactMap { id in trials.first { $0.id == id } }
        guard values.count == 3, let first=values.first,
              values.enumerated().allSatisfy({ index,trial in trial.trainingEligible && trial.key == first.key && trial.training == TrainingAttempt(runID:run.id,step:index) && trial.key.content == run.content.revision(for:trial.key.challenge) }) else { return nil }
        func median(_ a: [Double]) -> Double { a.sorted()[1] }
        key=first.key
        landing=median(values.map { abs($0.assessment.score!.reentryMS) })
        consistency=median(values.map { $0.assessment.score!.consistencyMS })
        drift=median(values.map { abs($0.assessment.score!.tempoDriftMSPerBeat) })
    }
    public func change(from baseline: TrainingSummary) -> String? {
        guard key == baseline.key else { return nil }
        func delta(_ old: Double,_ new: Double,_ unit: String) -> String {
            let d=old-new
            return abs(d)<0.5 ? "unchanged" : String(format:"%.1f %@ %@",abs(d),unit,d>0 ? "lower" : "higher")
        }
        return "Compared with your three-trial baseline: landing error \(delta(baseline.landing,landing,"ms")), consistency variation \(delta(baseline.consistency,consistency,"ms")), and drift magnitude \(delta(baseline.drift,drift,"ms per pulse")). Lower is better. This measures these conditions, not overall musicianship."
    }
}

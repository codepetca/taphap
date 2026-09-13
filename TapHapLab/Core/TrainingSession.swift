import Foundation

enum TrainingPhase: Equatable, Sendable {
    case idle
    case calibrating
    case warning
    case silentGap
    case result
}

struct TrainingSession: Equatable, Sendable {
    private(set) var phase: TrainingPhase = .idle
    private(set) var audibleTaps: [TimeInterval] = []
    private(set) var hiddenTaps: [TimeInterval] = []
    private(set) var pulse: PulseEstimate?
    private(set) var plan: GapPlan?
    private(set) var result: GapScore?

    mutating func begin() {
        phase = .calibrating
        audibleTaps = []
        hiddenTaps = []
        pulse = nil
        plan = nil
        result = nil
    }

    mutating func reset() {
        self = TrainingSession()
    }

    mutating func recordTap(at time: TimeInterval) {
        switch phase {
        case .calibrating:
            audibleTaps.append(time)
            if audibleTaps.count > 24 {
                audibleTaps.removeFirst(audibleTaps.count - 24)
            }
            pulse = PulseEstimator.fit(timestamps: audibleTaps)
        case .warning:
            if let plan, time >= plan.startTime {
                hiddenTaps.append(time)
            }
        case .silentGap:
            hiddenTaps.append(time)
        case .idle, .result:
            break
        }
    }

    mutating func prepareGap(now: TimeInterval, beatCount: Int = 8, leadBeats: Int = 3) -> GapPlan? {
        guard phase == .calibrating, let pulse, beatCount > 0, leadBeats > 0 else { return nil }
        let start = pulse.nextBeat(after: now + Double(leadBeats) * pulse.period)
        let plan = GapPlan(
            startTime: start,
            endTime: start + Double(beatCount) * pulse.period,
            beatCount: beatCount,
            pulse: pulse
        )
        self.plan = plan
        phase = .warning
        hiddenTaps = []
        return plan
    }

    mutating func beginGap() {
        guard phase == .warning else { return }
        phase = .silentGap
    }

    @discardableResult
    mutating func finishGap() -> GapScore? {
        guard phase == .silentGap, let plan else { return nil }
        result = GapScorer.score(timestamps: hiddenTaps, plan: plan)
        phase = .result
        return result
    }
}

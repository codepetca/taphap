import Foundation

public enum AssessmentKind: String, Codable, Sendable { case scored, partial, invalid }
public struct AudibleBaseline: Codable, Equatable, Sendable {
    public let phaseMS: Double
    public let periodMS: Double
    public let residualRMSMS: Double
    public let inputCount: Int
}
public struct ObservedIntervals: Codable, Equatable, Sendable {
    public let inputCount: Int
    public let intervalCount: Int
    public let medianSpacingMS: Double
    public let intervalSDMS: Double
    public let largestIntervalMS: Double
    public let shortIntervalCount: Int
    public let longIntervalCount: Int
    /// A suspected omitted/extra input is not repaired or counted as an inferred beat.
    public var hasIrregularIntervals: Bool { shortIntervalCount > 0 || longIntervalCount > 0 }
}
public struct TrialAssessment: Codable, Equatable, Sendable {
    public let kind: AssessmentKind
    public let score: TrialScore?
    public let baseline: AudibleBaseline?
    public let observedIntervals: ObservedIntervals?
    /// Beat-assignment failure from scoring, distinct from capture/environment invalidation.
    public let scoreIssue: TrialError?
    public let invalidation: TrialError?

    public static func invalid(_ reason: TrialError) -> TrialAssessment {
        TrialAssessment(kind:.invalid,score:nil,baseline:nil,observedIntervals:nil,scoreIssue:nil,invalidation:reason)
    }
    public var summary: String {
        if let score {
            return "\(score.diagnosis.capitalized) · consistency \(String(format:"%.1f",score.consistencyMS)) ms · drift \(String(format:"%+.1f",score.tempoDriftMSPerBeat)) ms/beat · landing \(String(format:"%+.1f",score.reentryMS)) ms."
        }
        guard kind == .partial, let baseline else {
            let reason: String
            switch invalidation {
            case .routeChanged: reason = "The audio route changed."
            case .interruption, .backgrounded, .cancelled: reason = "The trial was interrupted."
            case .invalidClock, .staleClock, .discontinuity: reason = "The timing reference became unreliable."
            case .multipleTouches: reason = "More than one contact was detected."
            case .invalidDirection: reason = "This exercise requires downward strokes."
            case .unstableBaseline, .missingInput, .duplicateInput: reason = "The opening inputs could not establish a reliable baseline."
            case .ambiguousInput: reason = "A stroke crossing could not be timestamped reliably."
            default: reason = "The trial could not be validated."
            }
            return "\(reason) Timing was not scored."
        }
        let opening = "Opening pulse: \(String(format:"%.0f",baseline.periodMS)) ms."
        let detail: String
        if let intervals = observedIntervals {
            if intervals.hasIrregularIntervals {
                detail = "Uneven input spacing; a missed or extra input is possible."
            } else {
                let ratio = intervals.medianSpacingMS/baseline.periodMS
                let trend = ratio > 1.03 ? "Inputs spread farther apart in silence" : ratio < 0.97 ? "Inputs moved closer together in silence" : "Input spacing stayed similar in silence"
                detail = "\(trend): \(String(format:"%.0f",intervals.medianSpacingMS)) ms median."
            }
        } else { detail = "Too few silent inputs for an interval comparison." }
        return "\(opening) \(detail) Landing unavailable; no full score."
    }
}

/// Keeps raw interval facts when a stable audible baseline exists but absolute beat identity does not.
/// Never guesses missing beats, unwraps a phase slip, or rescues invalid capture/clock data.
public enum Assessor {
    public static func assess(events: [InputEvent], map: BeatMap, invalidations: [TrialError] = []) -> TrialAssessment {
        if let reason = invalidations.first { return .invalid(reason) }
        do { try map.validate(); try Scorer.validateEvents(events) }
        catch { return .invalid(error as? TrialError ?? .malformedInput) }
        do {
            let score = try Scorer.score(events:events,map:map)
            return TrialAssessment(kind:.scored,score:score,baseline:nil,observedIntervals:nil,scoreIssue:nil,invalidation:nil)
        } catch let issue as TrialError {
            guard [.ambiguousInput,.missingInput,.duplicateInput].contains(issue) else { return .invalid(issue) }
            do {
                let phase = try Scorer.openingPhase(events:events,map:map)
                let offsets = try Scorer.assignedOffsets(events:events,map:map,range:map.baselineStartBeat...map.gapStartBeat-1,phase:phase)
                let values = (map.baselineStartBeat..<map.gapStartBeat).map { offsets[$0]! }
                let fit = Scorer.fit(values)
                guard abs(fit.slope) <= 0.005, fit.jitter <= 0.04 else { return .invalid(.unstableBaseline) }
                let periods = (map.baselineStartBeat..<map.gapStartBeat-1).map { map.seconds($0+1)-map.seconds($0) }
                let baseline = AudibleBaseline(phaseMS:Scorer.mean(values)*1000,periodMS:(Scorer.mean(periods)+fit.slope)*1000,residualRMSMS:fit.jitter*1000,inputCount:values.count)
                let envelope = try GapEnvelope(map:map)
                let gap = events.filter { $0.trackSeconds >= Double(envelope.silentStart)/map.sampleRate && $0.trackSeconds < Double(envelope.returnStart)/map.sampleRate }.map(\.trackSeconds)
                var intervals: ObservedIntervals?
                // Six complete observed intervals are the minimum for this descriptive comparison.
                if gap.count >= 7 {
                    let differences = zip(gap,gap.dropFirst()).map { ($1-$0)*1000 }
                    let sorted = differences.sorted(), middle = sorted.count/2
                    let median = sorted.count.isMultiple(of:2) ? (sorted[middle-1]+sorted[middle])/2 : sorted[middle]
                    intervals = ObservedIntervals(inputCount:gap.count,intervalCount:differences.count,medianSpacingMS:median,
                                                  intervalSDMS:Scorer.sd(differences),largestIntervalMS:sorted.last!,
                                                  shortIntervalCount:differences.filter { $0 < baseline.periodMS*0.5 }.count,
                                                  longIntervalCount:differences.filter { $0 > baseline.periodMS*1.5 }.count)
                }
                return TrialAssessment(kind:.partial,score:nil,baseline:baseline,observedIntervals:intervals,scoreIssue:issue,invalidation:nil)
            } catch { return .invalid(error as? TrialError ?? .malformedInput) }
        } catch { return .invalid(.malformedInput) }
    }
}

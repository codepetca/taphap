import Foundation
#if SWIFT_PACKAGE
import Phase1Core
#endif

public struct ResultCopy: Sendable {
    public let title: String
    public let message: String
    public init(_ assessment: TrialAssessment) {
        if let score=assessment.score, assessment.kind == .scored {
            switch score.diagnosis {
            case "steady": title="You held the groove."
            case "accelerated": title="You picked up speed."
            case "decelerated": title="Your pulse slowed down."
            case "jittered": title="Your spacing got uneven."
            default: title="Your pulse shifted."
            }
            message="The return is measured against your own opening rhythm. Try again and listen for where the song meets you."
        } else if assessment.kind == .partial {
            title="Some timing is clear."
            if let intervals=assessment.observedIntervals, let baseline=assessment.baseline {
                if intervals.hasIrregularIntervals {
                    message="We captured uneven spacing, possibly a missed or extra input. We can’t confidently place your landing."
                } else {
                    let ratio=intervals.medianSpacingMS/baseline.periodMS
                    message=(ratio > 1.03 ? "Your inputs spread farther apart in silence." : ratio < 0.97 ? "Your inputs moved closer together in silence." : "Your input spacing stayed similar in silence.") + " Your landing is uncertain, so this attempt can’t earn a personal best."
                }
            } else { message="Your opening rhythm was clear. There wasn’t enough unambiguous input in silence to judge the landing. Keep playing until the song ends." }
        } else {
            title="Let’s try that again."
            switch assessment.invalidation {
            case .routeChanged: message="The sound output changed. Reconnect the iPhone speaker and start a fresh attempt."
            case .backgrounded,.interruption,.cancelled: message="The attempt was interrupted. No timing result or personal best was recorded."
            case .multipleTouches: message="More than one finger touched at once. Use one finger, lifting between each tap or strum."
            case .invalidDirection: message="This challenge uses downstrums. Swipe down across the center string, then lift to reset."
            case .missingInput,.unstableBaseline,.duplicateInput: message="We couldn’t establish a clear opening rhythm. Start with the song’s pulse and keep going through its return."
            default: message="The timing couldn’t be verified. This attempt won’t affect your personal best."
            }
        }
    }
}

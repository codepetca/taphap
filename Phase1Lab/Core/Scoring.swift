import Foundation

public struct TrialScore: Codable, Equatable, Sendable {
    public let diagnosis: String
    public let baselinePhaseMS: Double
    public let baselinePeriodMS: Double
    public let baselineJitterMS: Double
    public let consistencyMS: Double
    public let tempoDriftMSPerBeat: Double
    public let accelerationMSPerBeatSquared: Double
    public let phaseShiftMS: Double
    public let reentryMS: Double
    public let inputCount: Int
}

public enum Scorer {
    static func mean(_ v: [Double]) -> Double { v.reduce(0,+)/Double(v.count) }
    static func sd(_ v: [Double]) -> Double { let m = mean(v); return sqrt(mean(v.map { ($0-m)*($0-m) })) }
    static func fit(_ y: [Double]) -> (intercept: Double, slope: Double, jitter: Double) {
        let x = y.indices.map(Double.init), mx = mean(x), my = mean(y)
        var numerator = 0.0
        var denominator = 0.0
        for i in y.indices { numerator += (x[i]-mx)*(y[i]-my); denominator += (x[i]-mx)*(x[i]-mx) }
        let slope = numerator / denominator
        let intercept = my-slope*mx
        return (intercept, slope, sd(zip(x,y).map { $1-intercept-slope*$0 }))
    }
    public static func score(events: [InputEvent], map: BeatMap, invalidations: [TrialError] = []) throws -> TrialScore {
        try map.validate()
        if let invalidation = invalidations.first { throw invalidation }
        guard !events.isEmpty else { throw TrialError.missingInput }
        guard events.allSatisfy({ [$0.trackSeconds,$0.hostSeconds,$0.observedHostSeconds].allSatisfy(\.isFinite)
            && $0.hostSeconds >= 0 && $0.observedHostSeconds >= $0.hostSeconds
            && $0.observedHostSeconds-$0.hostSeconds <= 0.25 }),
              zip(events,events.dropFirst()).allSatisfy({ $0.trackSeconds < $1.trackSeconds && $0.hostSeconds < $1.hostSeconds }),
              Set(events.map(\.mode)).count == 1 else { throw TrialError.malformedInput }
        guard events.allSatisfy({ $0.mode == .tap ? $0.direction == nil : $0.direction == .down }) else { throw TrialError.invalidDirection }
        // Fit phase only from the independently mapped audible section. Do not derive a beat map from touches.
        let opening = events.filter { $0.trackSeconds >= map.seconds(map.baselineStartBeat)-0.24 && $0.trackSeconds < map.seconds(map.gapStartBeat)-0.24 }
        guard opening.count >= 8 else { throw TrialError.missingInput }
        let offsets = opening.map { $0.trackSeconds-map.seconds(map.nearestBeat(to: $0.trackSeconds)) }.sorted()
        let phase = offsets[offsets.count/2]
        var assigned: [Int: Double] = [:]
        for event in events {
            let adjusted = event.trackSeconds-phase
            let index = map.nearestBeat(to: adjusted)
            guard index >= map.baselineStartBeat && index <= map.returnBeat+2 else { continue }
            let left = index > 0 ? map.seconds(index)-map.seconds(index-1) : 0.5
            let right = index+1 < map.beats.count ? map.seconds(index+1)-map.seconds(index) : left
            guard abs(adjusted-map.seconds(index)) < min(left,right)*0.45 else { throw TrialError.ambiguousInput }
            guard assigned[index] == nil else { throw TrialError.duplicateInput }
            assigned[index] = event.trackSeconds-map.seconds(index)
        }
        guard (map.baselineStartBeat...map.returnBeat+2).allSatisfy({ assigned[$0] != nil }) else { throw TrialError.missingInput }
        let baseline = (map.baselineStartBeat..<map.gapStartBeat).map { assigned[$0]! }
        let base = fit(baseline)
        guard abs(base.slope) <= 0.005, base.jitter <= 0.04 else { throw TrialError.unstableBaseline }
        // Fade-out beat is excluded: it is partially audible. Return beat is retained as the landing.
        let gap = (map.gapStartBeat+1...map.returnBeat).map { assigned[$0]! - mean(baseline) }
        let held = fit(gap)
        let half = gap.count/2
        let acceleration = (fit(Array(gap.suffix(half))).slope-fit(Array(gap.prefix(half))).slope)/Double(gap.count-half)
        let drift = held.slope-base.slope
        let diagnosis: String
        if held.jitter > 0.018 { diagnosis = "jittered" }
        else if drift < -0.002 { diagnosis = "accelerated" }
        else if drift > 0.002 { diagnosis = "decelerated" }
        else if abs(mean(gap)) > 0.035 { diagnosis = "shifted" }
        else { diagnosis = "steady" }
        let periods = (map.baselineStartBeat..<map.gapStartBeat-1).map { map.seconds($0+1)-map.seconds($0) }
        return TrialScore(diagnosis: diagnosis, baselinePhaseMS: mean(baseline)*1000,
                          baselinePeriodMS: (mean(periods)+base.slope)*1000, baselineJitterMS: base.jitter*1000,
                          consistencyMS: held.jitter*1000, tempoDriftMSPerBeat: drift*1000,
                          accelerationMSPerBeatSquared: acceleration*1000, phaseShiftMS: held.intercept*1000,
                          reentryMS: gap.last!*1000, inputCount: assigned.count)
    }
}

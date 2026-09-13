import Foundation

enum MonotonicClock {
    static var now: TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }
}

struct PulseEstimate: Equatable, Sendable {
    let period: TimeInterval
    let anchor: TimeInterval
    let residualJitter: TimeInterval
    let confidence: Double
    let acceptedTapCount: Int
    let totalTapCount: Int

    var bpm: Double { 60 / period }

    func nearestBeatIndex(to time: TimeInterval) -> Int {
        Int(((time - anchor) / period).rounded())
    }

    func beatTime(at index: Int) -> TimeInterval {
        anchor + Double(index) * period
    }

    func nearestBeatTime(to time: TimeInterval) -> TimeInterval {
        beatTime(at: nearestBeatIndex(to: time))
    }

    func nextBeat(after time: TimeInterval) -> TimeInterval {
        let index = Int(ceil((time - anchor) / period))
        return beatTime(at: index)
    }
}

enum PulseEstimator {
    static func fit(timestamps: [TimeInterval], minimumTapCount: Int = 8) -> PulseEstimate? {
        guard timestamps.count >= minimumTapCount else { return nil }

        let times = timestamps.sorted()
        let intervals = zip(times, times.dropFirst()).map { $1 - $0 }.filter { $0 > 0 }
        guard intervals.count >= minimumTapCount - 1 else { return nil }

        let initialPeriod = median(intervals)
        guard (0.25...1.72).contains(initialPeriod) else { return nil }

        let first = times[0]
        var beatIndices = times.map { Int((($0 - first) / initialPeriod).rounded()) }
        guard strictlyIncreasing(beatIndices) else { return nil }

        guard var line = linearFit(x: beatIndices.map(Double.init), y: times) else { return nil }
        guard (0.25...1.72).contains(line.slope) else { return nil }

        var residuals = zip(beatIndices, times).map { index, time in
            time - (line.intercept + Double(index) * line.slope)
        }
        let residualCenter = median(residuals)
        let residualMAD = median(residuals.map { abs($0 - residualCenter) })
        let cutoff = max(0.025, min(line.slope * 0.12, residualMAD * 3 + 0.010))

        let accepted = zip(zip(beatIndices, times), residuals).filter { pair, residual in
            _ = pair
            return abs(residual - residualCenter) <= cutoff
        }
        guard accepted.count >= minimumTapCount - 1 else { return nil }

        beatIndices = accepted.map { $0.0.0 }
        let acceptedTimes = accepted.map { $0.0.1 }
        guard let refined = linearFit(x: beatIndices.map(Double.init), y: acceptedTimes) else { return nil }
        line = refined
        guard (0.25...1.72).contains(line.slope) else { return nil }

        residuals = zip(beatIndices, acceptedTimes).map { index, time in
            time - (line.intercept + Double(index) * line.slope)
        }
        let jitter = rootMeanSquare(residuals)

        let countScore = min(1, Double(accepted.count) / 12)
        let acceptanceScore = Double(accepted.count) / Double(times.count)
        let jitterScore = max(0, 1 - jitter / (line.slope * 0.10))
        let confidence = min(1, countScore * acceptanceScore * jitterScore)

        guard confidence >= 0.45 else { return nil }

        return PulseEstimate(
            period: line.slope,
            anchor: line.intercept,
            residualJitter: jitter,
            confidence: confidence,
            acceptedTapCount: accepted.count,
            totalTapCount: times.count
        )
    }

    private static func strictlyIncreasing(_ values: [Int]) -> Bool {
        zip(values, values.dropFirst()).allSatisfy(<)
    }
}

struct GapPlan: Equatable, Sendable {
    let startTime: TimeInterval
    let endTime: TimeInterval
    let beatCount: Int
    let pulse: PulseEstimate

    var duration: TimeInterval { endTime - startTime }
}

struct GapScore: Equatable, Sendable {
    let endDriftMilliseconds: Double
    let meanAbsoluteErrorMilliseconds: Double
    let consistencyMilliseconds: Double
    let tempoSlopeMillisecondsPerSecond: Double
    let scoredTapCount: Int

    var direction: String {
        if abs(tempoSlopeMillisecondsPerSecond) < 4 { return "steady" }
        return tempoSlopeMillisecondsPerSecond < 0 ? "speeding up" : "slowing down"
    }

    var endSummary: String {
        if abs(endDriftMilliseconds) < 12 { return "On the pulse" }
        return "\(Int(abs(endDriftMilliseconds).rounded())) ms \(endDriftMilliseconds < 0 ? "early" : "late")"
    }
}

enum GapScorer {
    static func score(timestamps: [TimeInterval], plan: GapPlan) -> GapScore? {
        let pulse = plan.pulse
        let tolerance = pulse.period * 0.48
        let candidates = timestamps.filter {
            $0 >= plan.startTime - tolerance && $0 <= plan.endTime + tolerance
        }
        guard candidates.count >= 3 else { return nil }

        var bestTapByBeat: [Int: TimeInterval] = [:]
        for tap in candidates {
            let index = pulse.nearestBeatIndex(to: tap)
            let expected = pulse.beatTime(at: index)
            guard expected >= plan.startTime - tolerance, expected <= plan.endTime + tolerance else { continue }
            if let previous = bestTapByBeat[index] {
                if abs(tap - expected) < abs(previous - expected) {
                    bestTapByBeat[index] = tap
                }
            } else {
                bestTapByBeat[index] = tap
            }
        }

        let observations = bestTapByBeat.keys.sorted().compactMap { index -> (Double, Double, TimeInterval)? in
            guard let tap = bestTapByBeat[index] else { return nil }
            let expected = pulse.beatTime(at: index)
            return (expected, tap - expected, tap)
        }
        guard observations.count >= 3 else { return nil }

        let errors = observations.map(\.1)
        let meanAbsoluteError = errors.map(abs).reduce(0, +) / Double(errors.count)
        let endDrift = errors.last ?? 0

        let origin = observations[0].0
        let slope = linearFit(
            x: observations.map { $0.0 - origin },
            y: errors
        )?.slope ?? 0

        let intervalDeviations = zip(observations, observations.dropFirst()).compactMap { first, second -> Double? in
            let expectedInterval = second.0 - first.0
            guard expectedInterval > 0 else { return nil }
            return (second.2 - first.2) - expectedInterval
        }
        let consistency = rootMeanSquare(intervalDeviations)

        return GapScore(
            endDriftMilliseconds: endDrift * 1_000,
            meanAbsoluteErrorMilliseconds: meanAbsoluteError * 1_000,
            consistencyMilliseconds: consistency * 1_000,
            tempoSlopeMillisecondsPerSecond: slope * 1_000,
            scoredTapCount: observations.count
        )
    }
}

struct KnownGridDiagnostics: Equatable, Sendable {
    let meanOffsetMilliseconds: Double
    let jitterMilliseconds: Double
    let tapCount: Int

    static func measure(
        timestamps: [TimeInterval],
        anchor: TimeInterval,
        period: TimeInterval
    ) -> KnownGridDiagnostics? {
        guard !timestamps.isEmpty, period > 0 else { return nil }
        let errors = timestamps.map { tap -> TimeInterval in
            let index = ((tap - anchor) / period).rounded()
            return tap - (anchor + index * period)
        }
        let mean = errors.reduce(0, +) / Double(errors.count)
        let centered = errors.map { $0 - mean }
        return KnownGridDiagnostics(
            meanOffsetMilliseconds: mean * 1_000,
            jitterMilliseconds: rootMeanSquare(centered) * 1_000,
            tapCount: errors.count
        )
    }
}

private func median(_ values: [Double]) -> Double {
    guard !values.isEmpty else { return 0 }
    let sorted = values.sorted()
    let middle = sorted.count / 2
    if sorted.count.isMultiple(of: 2) {
        return (sorted[middle - 1] + sorted[middle]) / 2
    }
    return sorted[middle]
}

private func rootMeanSquare(_ values: [Double]) -> Double {
    guard !values.isEmpty else { return 0 }
    return sqrt(values.map { $0 * $0 }.reduce(0, +) / Double(values.count))
}

private func linearFit(x: [Double], y: [Double]) -> (slope: Double, intercept: Double)? {
    guard x.count == y.count, x.count >= 2 else { return nil }
    let meanX = x.reduce(0, +) / Double(x.count)
    let meanY = y.reduce(0, +) / Double(y.count)
    let denominator = x.map { pow($0 - meanX, 2) }.reduce(0, +)
    guard denominator > .ulpOfOne else { return nil }
    let numerator = zip(x, y).map { ($0 - meanX) * ($1 - meanY) }.reduce(0, +)
    let slope = numerator / denominator
    return (slope, meanY - slope * meanX)
}

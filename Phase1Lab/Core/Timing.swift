import Foundation

public enum TrialError: String, Error, Codable, Sendable {
    case invalidMap, invalidSchedule, invalidClock, staleClock, discontinuity
    case routeChanged, interruption, backgrounded, cancelled, multipleTouches
    case missingInput, duplicateInput, ambiguousInput, unstableBaseline, invalidDirection
    case malformedInput, assetMismatch
}

public struct BeatMap: Codable, Sendable {
    public let revision: String
    public let sampleRate: Double
    public let frameCount: Int64
    public let beats: [Int64]
    public let downbeatIndices: [Int]
    public let baselineStartBeat: Int
    public let gapStartBeat: Int
    public let returnBeat: Int
    public let fadeFrames: Int64

    public func validate() throws {
        guard sampleRate.isFinite, sampleRate > 0, frameCount > 0,
              beats.count >= 12, beats.first! >= 0, beats.last! < frameCount,
              zip(beats, beats.dropFirst()).allSatisfy({ $0 < $1 }),
              !downbeatIndices.isEmpty, downbeatIndices.allSatisfy({ beats.indices.contains($0) }),
              Set(downbeatIndices).count == downbeatIndices.count,
              baselineStartBeat >= 0, gapStartBeat - baselineStartBeat >= 8,
              returnBeat - gapStartBeat >= 4, returnBeat + 2 < beats.count,
              fadeFrames > 0, fadeFrames < beats[gapStartBeat + 1] - beats[gapStartBeat],
              fadeFrames < beats[returnBeat + 1] - beats[returnBeat]
        else { throw TrialError.invalidMap }
    }
    public func seconds(_ index: Int) -> Double { Double(beats[index]) / sampleRate }
    public func nearestBeat(to seconds: Double) -> Int {
        beats.indices.min(by: { abs(self.seconds($0)-seconds) < abs(self.seconds($1)-seconds) })!
    }
}

/// Immutable sample-domain schedule applied to decoded PCM before it is queued.
/// Playback traverses every sample, including zero-gain samples; no UI timer changes gain.
public struct GapEnvelope: Sendable {
    public let fadeStart: Int64
    public let silentStart: Int64
    public let returnStart: Int64
    public let fullReturn: Int64
    public init(map: BeatMap) throws {
        try map.validate()
        fadeStart = map.beats[map.gapStartBeat]
        silentStart = fadeStart + map.fadeFrames
        returnStart = map.beats[map.returnBeat]
        fullReturn = returnStart + map.fadeFrames
        guard silentStart < returnStart, fullReturn < map.frameCount else { throw TrialError.invalidSchedule }
    }
    public func gain(at frame: Int64) -> Float {
        if frame < fadeStart || frame >= fullReturn { return 1 }
        if frame < silentStart { return Float(0.5 + 0.5 * cos(.pi * Double(frame-fadeStart)/Double(silentStart-fadeStart))) }
        if frame < returnStart { return 0 }
        return Float(0.5 - 0.5 * cos(.pi * Double(frame-returnStart)/Double(fullReturn-returnStart)))
    }
}

/// Host seconds use mach_absolute_time units converted with AVAudioTime.seconds(forHostTime:).
/// UITouch.timestamp is boot-relative seconds; wall time and UI observation time are never score inputs.
public struct AudioAnchor: Codable, Sendable {
    public let hostSeconds: Double
    public let sample: Double
    public let sampleRate: Double
    public init(hostSeconds: Double, sample: Double, sampleRate: Double) {
        self.hostSeconds = hostSeconds; self.sample = sample; self.sampleRate = sampleRate
    }
    public func trackSeconds(touchHostSeconds: Double, observedHostSeconds: Double) throws -> Double {
        guard [hostSeconds,sample,sampleRate,touchHostSeconds,observedHostSeconds].allSatisfy(\.isFinite),
              sampleRate > 0, sample >= 0, touchHostSeconds >= 0,
              touchHostSeconds <= observedHostSeconds + 0.002 else { throw TrialError.invalidClock }
        guard abs(observedHostSeconds-hostSeconds) <= 0.25,
              observedHostSeconds-touchHostSeconds <= 0.25 else { throw TrialError.staleClock }
        return sample/sampleRate + touchHostSeconds-hostSeconds
    }
    public func validateContinuation(from previous: AudioAnchor) throws {
        guard sampleRate == previous.sampleRate, hostSeconds >= previous.hostSeconds,
              sample >= previous.sample else { throw TrialError.discontinuity }
        let error = (sample-previous.sample)/sampleRate - (hostSeconds-previous.hostSeconds)
        guard abs(error) <= 0.002 else { throw TrialError.discontinuity }
    }
}

public enum InputMode: String, Codable, Sendable { case tap, strum }
public enum StrokeDirection: String, Codable, Sendable { case down, up }
public struct InputEvent: Codable, Sendable {
    public let trackSeconds: Double
    public let hostSeconds: Double
    public let observedHostSeconds: Double
    public let mode: InputMode
    public let direction: StrokeDirection?
    public init(trackSeconds: Double, hostSeconds: Double, observedHostSeconds: Double, mode: InputMode, direction: StrokeDirection? = nil) {
        self.trackSeconds = trackSeconds; self.hostSeconds = hostSeconds
        self.observedHostSeconds = observedHostSeconds; self.mode = mode; self.direction = direction
    }
}
public struct TouchPoint: Sendable {
    public let y: Double
    public let hostSeconds: Double
    public init(y: Double, hostSeconds: Double) { self.y = y; self.hostSeconds = hostSeconds }
}
public struct Crossing: Equatable, Sendable {
    public let hostSeconds: Double
    public let direction: StrokeDirection
    public let bracketSeconds: Double
}
/// One reference crossing per contact. Rearm by lifting; contact beginning on the line is ambiguous.
public struct StrumTracker: Sendable {
    private var previous: TouchPoint?
    private var emitted = false
    public init() {}
    public mutating func begin(_ point: TouchPoint) { previous = point; emitted = false }
    public mutating func cancel() { previous = nil; emitted = false }
    public mutating func move(_ point: TouchPoint, referenceY: Double) throws -> Crossing? {
        guard point.y.isFinite, point.hostSeconds.isFinite, referenceY.isFinite else { throw TrialError.malformedInput }
        guard let p = previous else { return nil }
        guard point.hostSeconds > p.hostSeconds else { return nil } // duplicate coalesced samples
        previous = point
        guard !emitted else { return nil }
        let a = p.y-referenceY, b = point.y-referenceY
        guard (a < 0 && b >= 0) || (a > 0 && b <= 0) else { return nil }
        guard point.hostSeconds-p.hostSeconds <= 0.05 else { throw TrialError.ambiguousInput }
        let fraction = -a/(b-a)
        emitted = true
        return Crossing(hostSeconds: p.hostSeconds + fraction*(point.hostSeconds-p.hostSeconds),
                        direction: b > a ? .down : .up, bracketSeconds: point.hostSeconds-p.hostSeconds)
    }
}

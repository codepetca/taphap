import AVFAudio
import Darwin

struct ReferenceGrid: Equatable, Sendable {
    let anchor: TimeInterval
    let period: TimeInterval

    var bpm: Double { 60 / period }
}

final class ReferenceClickPlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var isConfigured = false

    func start(bpm: Double = 120) throws -> ReferenceGrid {
        stop()
        let period = 60 / bpm
        let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2)!

        if !isConfigured {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            isConfigured = true
        }

        let buffer = makeLoopBuffer(format: format, period: period, beatCount: 4)
        player.scheduleBuffer(buffer, at: nil, options: .loops)
        engine.prepare()
        try engine.start()

        let leadTime: TimeInterval = 0.20
        let hostNow = mach_absolute_time()
        let startHostTime = hostNow + AVAudioTime.hostTime(forSeconds: leadTime)
        let anchor = MonotonicClock.now + leadTime
        player.play(at: AVAudioTime(hostTime: startHostTime))

        return ReferenceGrid(anchor: anchor, period: period)
    }

    func stop() {
        player.stop()
        if engine.isRunning {
            engine.stop()
        }
    }

    private func makeLoopBuffer(
        format: AVAudioFormat,
        period: TimeInterval,
        beatCount: Int
    ) -> AVAudioPCMBuffer {
        let framesPerBeat = Int((format.sampleRate * period).rounded())
        let frameCount = AVAudioFrameCount(framesPerBeat * beatCount)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        guard let channels = buffer.floatChannelData else { return buffer }
        let clickFrames = min(Int(format.sampleRate * 0.035), framesPerBeat)

        for channel in 0..<Int(format.channelCount) {
            channels[channel].initialize(repeating: 0, count: Int(frameCount))
        }

        for beat in 0..<beatCount {
            let frequency = beat == 0 ? 1_800.0 : 1_250.0
            let amplitude = beat == 0 ? 0.72 : 0.48
            let startFrame = beat * framesPerBeat

            for frame in 0..<clickFrames {
                let seconds = Double(frame) / format.sampleRate
                let envelope = exp(-seconds * 70)
                let sample = Float(sin(2 * .pi * frequency * seconds) * envelope * amplitude)
                for channel in 0..<Int(format.channelCount) {
                    channels[channel][startFrame + frame] = sample
                }
            }
        }
        return buffer
    }
}

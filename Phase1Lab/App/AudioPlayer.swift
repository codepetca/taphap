import AVFAudio
import CryptoKit
import Darwin

/// Only the main actor owns the engine and reads its public render clock.
/// PCM is prepared once on start. The audio renderer consumes an immutable full-length buffer.
@MainActor
final class LabAudioPlayer {
    private(set) var engine = AVAudioEngine()
    private(set) var player = AVAudioPlayerNode()
    private(set) var map: BeatMap!
    private(set) var previousAnchor: AudioAnchor?
    private(set) var scheduledHostSeconds: Double = 0
    private(set) var anchorCount = 0
    private(set) var maximumClockResidualMS: Double = 0
    private(set) var route: [String: String] = [:]
    private var configured = false

    static func hostNow() -> Double { AVAudioTime.seconds(forHostTime: mach_absolute_time()) }

    static func loadBuffer(bundle: Bundle = .main) throws -> (BeatMap, AVAudioPCMBuffer) {
        guard let mapURL = bundle.url(forResource:"beat-map",withExtension:"json"),
              let audioURL = bundle.url(forResource:"ClockworkGarden",withExtension:"wav") else { throw TrialError.assetMismatch }
        let mapData = try Data(contentsOf:mapURL), audioData = try Data(contentsOf:audioURL)
        let hash = SHA256.hash(data:audioData).map { String(format:"%02x",$0) }.joined()
        let mapHash = SHA256.hash(data:mapData).map { String(format:"%02x",$0) }.joined()
        guard hash == AssetRevision.audioSHA256, mapHash == AssetRevision.mapSHA256 else { throw TrialError.assetMismatch }
        let map = try JSONDecoder().decode(BeatMap.self,from:mapData)
        try map.validate()
        let file = try AVAudioFile(forReading:audioURL)
        guard file.length == map.frameCount, file.processingFormat.sampleRate == map.sampleRate,
              file.processingFormat.channelCount == 1,
              let buffer = AVAudioPCMBuffer(pcmFormat:file.processingFormat,frameCapacity:AVAudioFrameCount(file.length)) else { throw TrialError.assetMismatch }
        try file.read(into:buffer)
        guard let samples = buffer.floatChannelData?[0] else { throw TrialError.assetMismatch }
        let envelope = try GapEnvelope(map:map)
        for frame in 0..<Int(buffer.frameLength) { samples[frame] *= envelope.gain(at:Int64(frame)) }
        return (map,buffer)
    }
    func start() throws {
        stop()
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode:.default)
        try session.setPreferredSampleRate(48000)
        try session.setPreferredIOBufferDuration(0.005)
        try session.setActive(true)
        let (map,buffer) = try Self.loadBuffer()
        self.map = map
        previousAnchor = nil; anchorCount = 0; maximumClockResidualMS = 0
        route = ["outputs": session.currentRoute.outputs.map { "\($0.portType.rawValue):\($0.portName)" }.joined(separator:","),
                 "sessionSampleRate":String(session.sampleRate),"outputLatencyReportedSeconds":String(session.outputLatency),
                 "ioBufferDurationSeconds":String(session.ioBufferDuration),"audioSHA256":AssetRevision.audioSHA256,
                 "mapSHA256":AssetRevision.mapSHA256,"latencyCorrection":"none; stable combined offset fitted from audible input"]
        if !configured {
            engine.attach(player); engine.connect(player,to:engine.mainMixerNode,format:buffer.format); configured = true
        }
        player.scheduleBuffer(buffer,at:nil,options:[])
        engine.prepare(); try engine.start()
        let host = mach_absolute_time() + AVAudioTime.hostTime(forSeconds:0.25)
        scheduledHostSeconds = AVAudioTime.seconds(forHostTime:host)
        player.play(at:AVAudioTime(hostTime:host))
    }
    func anchor() throws -> AudioAnchor? {
        guard engine.isRunning else { throw TrialError.discontinuity }
        guard let node = player.lastRenderTime, node.isHostTimeValid,
              let time = player.playerTime(forNodeTime:node), time.isSampleTimeValid,
              time.sampleTime >= 0 else { return nil }
        let anchor = AudioAnchor(hostSeconds:AVAudioTime.seconds(forHostTime:node.hostTime),sample:Double(time.sampleTime),sampleRate:time.sampleRate)
        if let previous = previousAnchor {
            try anchor.validateContinuation(from:previous)
            let residual = abs((anchor.sample-previous.sample)/anchor.sampleRate-(anchor.hostSeconds-previous.hostSeconds))*1000
            maximumClockResidualMS = max(maximumClockResidualMS,residual)
        }
        previousAnchor = anchor; anchorCount += 1
        return anchor
    }
    func rebuildAfterMediaServicesReset() {
        stop()
        engine = AVAudioEngine(); player = AVAudioPlayerNode(); configured = false
        previousAnchor = nil
    }
    func stop() { player.stop(); engine.stop() }
}

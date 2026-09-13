import AVFAudio
import XCTest
@testable import TapHapPhase1

@MainActor
final class AudioTests: XCTestCase {
    func testShippedPCMHasExactSilenceAndUnchangedPostReturnPosition() throws {
        let (map,gated) = try LabAudioPlayer.loadBuffer()
        let file = try AVAudioFile(forReading:Bundle.main.url(forResource:"ClockworkGarden",withExtension:"wav")!)
        let original = AVAudioPCMBuffer(pcmFormat:file.processingFormat,frameCapacity:AVAudioFrameCount(file.length))!
        try file.read(into:original)
        let envelope = try GapEnvelope(map:map)
        let a = original.floatChannelData![0], b = gated.floatChannelData![0]
        var silentOriginalEnergy = 0.0
        for frame in 0..<Int(map.frameCount) {
            if frame >= envelope.silentStart && frame < envelope.returnStart {
                XCTAssertEqual(b[frame],0); silentOriginalEnergy += Double(a[frame]*a[frame])
            }
            if frame < envelope.fadeStart || frame >= envelope.fullReturn { XCTAssertEqual(a[frame],b[frame]) }
        }
        XCTAssertGreaterThan(silentOriginalEnergy,100)
    }
    func testOfflineEngineRendersContinuousFullTrackWithGap() throws {
        let (map,source) = try LabAudioPlayer.loadBuffer()
        let engine = AVAudioEngine(), player = AVAudioPlayerNode()
        engine.attach(player); engine.connect(player,to:engine.mainMixerNode,format:source.format)
        try engine.enableManualRenderingMode(.offline,format:source.format,maximumFrameCount:1024)
        player.scheduleBuffer(source); try engine.start(); player.play()
        defer { player.stop(); engine.stop() }
        let buffer = AVAudioPCMBuffer(pcmFormat:engine.manualRenderingFormat,frameCapacity:1024)!
        var rendered: Int64 = 0, retry = 0, gapEnergy = 0.0, returnEnergy = 0.0
        let gap = try GapEnvelope(map:map)
        while rendered < map.frameCount {
            let before = engine.manualRenderingSampleTime
            let result = try engine.renderOffline(AVAudioFrameCount(min(1024,map.frameCount-rendered)),to:buffer)
            if result != .success { retry += 1; XCTAssertLessThan(retry,10); if retry >= 10 { break }; continue }
            for index in 0..<Int(buffer.frameLength) {
                let sample = before+Int64(index), value = Double(buffer.floatChannelData![0][index])
                // Exclude a small boundary region from engine filter tails; pure PCM assertion is exact above.
                if sample > gap.silentStart+1024 && sample < gap.returnStart { gapEnergy += value*value }
                if sample >= gap.fullReturn && sample < gap.fullReturn+48000 { returnEnergy += value*value }
            }
            rendered += Int64(buffer.frameLength)
            XCTAssertEqual(engine.manualRenderingSampleTime,rendered)
        }
        XCTAssertEqual(rendered,map.frameCount); XCTAssertEqual(gapEnergy,0,accuracy:1e-12); XCTAssertGreaterThan(returnEnergy,1)
        print("OFFLINE_ENGINE frames=\(rendered) gapEnergy=\(gapEnergy) returnEnergy=\(returnEnergy)")
    }
    func testPhysicalOrSimulatorRenderClockTraversesAllGapBoundaries() async throws {
        let audio = LabAudioPlayer()
        try audio.start()
        defer { audio.stop() }
        let gap = try GapEnvelope(map:audio.map)
        var crossed = Set<String>(), first: AudioAnchor?, last: AudioAnchor?
        let deadline = LabAudioPlayer.hostNow()+36
        while LabAudioPlayer.hostNow() < deadline {
            try await Task.sleep(for:.milliseconds(50))
            if let anchor = try audio.anchor() {
                if first == nil { first = anchor }
                last = anchor
                XCTAssertLessThan(abs(LabAudioPlayer.hostNow()-anchor.hostSeconds),0.25)
                if anchor.sample >= Double(gap.fadeStart) { crossed.insert("fade") }
                if anchor.sample >= Double(gap.silentStart) { crossed.insert("silent") }
                if anchor.sample >= Double(gap.returnStart) { crossed.insert("return") }
                if anchor.sample >= Double(gap.fullReturn) { crossed.insert("fullReturn") }
                if anchor.sample >= Double(audio.map.frameCount) { crossed.insert("end"); break }
            }
        }
        XCTAssertEqual(crossed,Set(["fade","silent","return","fullReturn","end"]))
        XCTAssertNotNil(first); XCTAssertNotNil(last); XCTAssertGreaterThan(audio.anchorCount,500)
        XCTAssertLessThanOrEqual(audio.maximumClockResidualMS,2)
        let evidence: [String:Any] = ["route":audio.route,"crossed":crossed.sorted(),"anchorCount":audio.anchorCount,
                                    "maximumClockResidualMS":audio.maximumClockResidualMS,"acousticObservation":"NOT OBSERVED",
                                    "firstSample":first?.sample ?? -1,"lastSample":last?.sample ?? -1]
        let data = try JSONSerialization.data(withJSONObject:evidence,options:[.prettyPrinted,.sortedKeys])
        let attachment = XCTAttachment(data:data,uniformTypeIdentifier:"public.json"); attachment.name = "render-clock-evidence"; attachment.lifetime = .keepAlways
        add(attachment)
        print("RENDER_CLOCK \(String(data:data,encoding:.utf8)!)")
    }
}

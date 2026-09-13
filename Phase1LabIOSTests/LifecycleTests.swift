import AVFAudio
import UIKit
import XCTest
@testable import TapHapPhase1

@MainActor
final class LifecycleTests: XCTestCase {
    func testEveryEnvironmentalEventDuringPreparationCancelsArming() throws {
        let notifications: [Notification.Name] = [AVAudioSession.routeChangeNotification,
            AVAudioSession.interruptionNotification, AVAudioSession.mediaServicesWereResetNotification,
            .AVAudioEngineConfigurationChange, UIApplication.willResignActiveNotification]
        for notification in notifications {
            let model = LabModel()
            var arm: (() -> Void)?
            model.start(deferArming: { arm = $0 })
            XCTAssertTrue(model.starting)
            NotificationCenter.default.post(name:notification,object:nil)
            XCTAssertFalse(model.starting); XCTAssertFalse(model.running)
            try XCTUnwrap(arm)()
            XCTAssertFalse(model.running,notification.rawValue)
            XCTAssertFalse(model.audio.engine.isRunning)
            XCTAssertEqual(model.lastAssessment?.kind,.invalid)
            XCTAssertNil(model.lastAssessment?.baseline)
            XCTAssertNil(model.lastAssessment?.observedIntervals)
            XCTAssertNil(model.lastAssessment?.score)
        }
    }
    func testMediaServicesResetRebuildsObjectsAndNextTrialRenders() async throws {
        let model = LabModel()
        let previousEngine = model.audio.engine, previousPlayer = model.audio.player
        NotificationCenter.default.post(name:AVAudioSession.mediaServicesWereResetNotification,object:nil)
        XCTAssertFalse(model.audio.engine === previousEngine)
        XCTAssertFalse(model.audio.player === previousPlayer)
        try model.audio.start()
        defer { model.audio.stop() }
        try await Task.sleep(for:.milliseconds(600))
        let anchor = try XCTUnwrap(model.audio.anchor())
        XCTAssertGreaterThan(anchor.sample,0)
        XCTAssertTrue(model.audio.engine.isRunning)
    }
}

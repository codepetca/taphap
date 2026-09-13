import SwiftUI
import UIKit

struct TapCaptureView: UIViewRepresentable {
    let onTap: (TimeInterval) -> Void

    func makeUIView(context: Context) -> TouchSurface {
        let view = TouchSurface()
        view.onTap = onTap
        return view
    }

    func updateUIView(_ uiView: TouchSurface, context: Context) {
        uiView.onTap = onTap
    }
}

final class TouchSurface: UIView {
    var onTap: ((TimeInterval) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = "Tap the pulse"
        accessibilityHint = "Double tap in time with the music"
        isMultipleTouchEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        onTap?(event?.timestamp ?? MonotonicClock.now)
    }

    override func accessibilityActivate() -> Bool {
        onTap?(MonotonicClock.now)
        return true
    }
}

import SwiftUI
import UIKit

struct InputSurface: UIViewRepresentable {
    @ObservedObject var model: LabModel
    func makeUIView(context: Context) -> LabTouchView { let view = LabTouchView(); view.model = model; return view }
    func updateUIView(_ view: LabTouchView, context: Context) { view.model = model; view.setNeedsDisplay() }
}
final class LabTouchView: UIView {
    weak var model: LabModel?
    private var tracker = StrumTracker()
    private var activeTouch: UITouch?
    override init(frame: CGRect) {
        super.init(frame:frame)
        isMultipleTouchEnabled = true
        backgroundColor = .secondarySystemBackground
        isAccessibilityElement = true
        accessibilityLabel = "Physical timing input surface"
        accessibilityHint = "Direct touch required in this feasibility lab. Accessibility activation is not a timestamped physical input."
    }
    required init?(coder:NSCoder) { fatalError("init(coder:) unavailable") }
    override func draw(_ rect: CGRect) {
        guard model?.mode == .strum, let c = UIGraphicsGetCurrentContext() else { return }
        c.setStrokeColor(UIColor.label.cgColor); c.setLineWidth(2)
        c.move(to:CGPoint(x:20,y:bounds.midY)); c.addLine(to:CGPoint(x:bounds.width-20,y:bounds.midY)); c.strokePath()
    }
    override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent?) {
        guard model?.running == true else { return }
        guard touches.count == 1, activeTouch == nil, let touch = touches.first else { model?.invalidate(.multipleTouches); return }
        activeTouch = touch
        if model?.mode == .tap { model?.capture(hostSeconds:touch.timestamp,direction:nil) }
        else { tracker.begin(TouchPoint(y:touch.location(in:self).y,hostSeconds:touch.timestamp)) }
    }
    override func touchesMoved(_ touches:Set<UITouch>,with event:UIEvent?) { process(touches,event:event) }
    private func process(_ touches:Set<UITouch>,event:UIEvent?) {
        guard model?.mode == .strum, let activeTouch, touches.contains(activeTouch) else { return }
        // Coalesced samples only; predicted touches never enter scoring. Include final actual point.
        let samples = (event?.coalescedTouches(for:activeTouch) ?? [activeTouch]).sorted { $0.timestamp < $1.timestamp }
        for touch in samples {
            do {
                if let crossing = try tracker.move(TouchPoint(y:touch.location(in:self).y,hostSeconds:touch.timestamp),referenceY:bounds.midY) {
                    model?.capture(hostSeconds:crossing.hostSeconds,direction:crossing.direction,bracketSeconds:crossing.bracketSeconds)
                }
            } catch { model?.invalidate(error as? TrialError ?? .ambiguousInput) }
        }
    }
    override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?) {
        process(touches,event:event)
        if let activeTouch, touches.contains(activeTouch) { self.activeTouch = nil; tracker.cancel() }
    }
    override func touchesCancelled(_ touches:Set<UITouch>,with event:UIEvent?) {
        activeTouch = nil; tracker.cancel(); model?.invalidate(.cancelled)
    }
}

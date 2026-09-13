import SwiftUI
import UIKit

struct GameInputSurface: UIViewRepresentable {
    @ObservedObject var model: GameModel
    func makeUIView(context: Context) -> GameTouchView { let view = GameTouchView(); view.model = model; return view }
    func updateUIView(_ view: GameTouchView, context: Context) { view.model = model; view.accessibilityLabel = model.mode == .tap ? "Tap surface" : "Strum surface"; view.setNeedsDisplay() }
}
final class GameTouchView: UIView {
    weak var model: GameModel?
    private var tracker = StrumTracker()
    private var activeTouch: UITouch?
    override init(frame: CGRect) {
        super.init(frame:frame)
        isMultipleTouchEnabled = true
        backgroundColor = UIColor(red:0.10,green:0.19,blue:0.21,alpha:1)
        layer.cornerRadius = 28
        isAccessibilityElement = true
        accessibilityLabel = "Play surface"
        accessibilityIdentifier = "playSurface"
        accessibilityTraits = [.allowsDirectInteraction]
        accessibilityDirectTouchOptions = [.silentOnTouch]
        accessibilityHint = "Touch directly to play. For Strum, swipe downward across the center, then lift."
    }
    required init?(coder:NSCoder) { fatalError("init(coder:) unavailable") }
    override func draw(_ rect: CGRect) {
        guard let c = UIGraphicsGetCurrentContext() else { return }
        if model?.mode == .tap {
            c.setStrokeColor(UIColor.white.cgColor); c.setLineWidth(activeTouch == nil ? 3 : 6)
            let diameter = min(bounds.width,bounds.height)*0.65
            c.strokeEllipse(in:CGRect(x:bounds.midX-diameter/2,y:bounds.midY-diameter/2,width:diameter,height:diameter))
            return
        }
        c.setStrokeColor(UIColor.white.cgColor); c.setLineWidth(activeTouch == nil ? 2 : 5)
        c.move(to:CGPoint(x:20,y:bounds.midY)); c.addLine(to:CGPoint(x:bounds.width-20,y:bounds.midY)); c.strokePath()
    }
    override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent?) {
        guard model?.running == true else { return }
        guard touches.count == 1, activeTouch == nil, let touch = touches.first else { model?.invalidate(.multipleTouches); return }
        activeTouch = touch
        setNeedsDisplay() // Only a real contact changes the stroke; no autonomous pulse.
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
        if let activeTouch, touches.contains(activeTouch) { self.activeTouch = nil; tracker.cancel(); setNeedsDisplay() }
    }
    override func touchesCancelled(_ touches:Set<UITouch>,with event:UIEvent?) {
        activeTouch = nil; tracker.cancel(); setNeedsDisplay(); model?.invalidate(.cancelled)
    }
}

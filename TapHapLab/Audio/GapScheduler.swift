import Foundation

final class GapScheduler {
    private let queue = DispatchQueue(label: "ca.codepet.taphap.gap-scheduler", qos: .userInteractive)
    private var startItem: DispatchWorkItem?
    private var endItem: DispatchWorkItem?

    func schedule(
        plan: GapPlan,
        onStart: @escaping (_ targetTime: TimeInterval) -> Void,
        onEnd: @escaping (_ targetTime: TimeInterval) -> Void
    ) {
        cancel()

        let startItem = DispatchWorkItem { onStart(plan.startTime) }
        let endItem = DispatchWorkItem { onEnd(plan.endTime) }
        self.startItem = startItem
        self.endItem = endItem

        queue.asyncAfter(deadline: deadline(for: plan.startTime), execute: startItem)
        queue.asyncAfter(deadline: deadline(for: plan.endTime), execute: endItem)
    }

    func cancel() {
        startItem?.cancel()
        endItem?.cancel()
        startItem = nil
        endItem = nil
    }

    private func deadline(for monotonicTime: TimeInterval) -> DispatchTime {
        let remaining = max(0, monotonicTime - MonotonicClock.now)
        return .now() + remaining
    }
}

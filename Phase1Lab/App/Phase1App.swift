import SwiftUI

@main
struct Phase1App: App {
    @StateObject private var model = LabModel()
    var body: some Scene {
        WindowGroup {
            VStack(spacing:16) {
                Text("TapHap · Phase 1 Lab").font(.headline)
                Picker("Input",selection:$model.mode) {
                    Text("Tap").tag(InputMode.tap); Text("Strum").tag(InputMode.strum)
                }.pickerStyle(.segmented).disabled(model.running || model.starting)
                Text(model.mode == .tap ? "Touch down on every quarter-note pulse." : "Swipe downward across the line on each pulse. Lift before the next stroke.")
                Text(model.status).font(.callout).frame(minHeight:75)
                ProgressView(value:model.progress).accessibilityLabel("Overall track progress")
                InputSurface(model:model).frame(maxHeight:.infinity).clipShape(RoundedRectangle(cornerRadius:16))
                Button(model.running || model.starting ? "Cancel trial" : "Start 34-second trial") {
                    if model.running || model.starting { model.invalidate(.cancelled) } else { model.start() }
                }.buttonStyle(.borderedProminent).accessibilityIdentifier("trialButton")
                Text("Original local test music · no beat cues during silence").font(.caption)
            }.padding()
            .onAppear {
                if ProcessInfo.processInfo.arguments.contains("--autorun") { DispatchQueue.main.asyncAfter(deadline:.now()+0.5) { model.start() } }
            }
        }
    }
}

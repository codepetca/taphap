import SwiftUI

@main
struct TapHapApp: App {
    @StateObject private var model=GameModel()
    var body: some Scene { WindowGroup { GameView(model:model) } }
}
struct GameView: View {
    @ObservedObject var model: GameModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    private let ink=Color(red:0.08,green:0.15,blue:0.16)
    private let paper=Color(red:0.96,green:0.95,blue:0.89)
    private let accent=Color(red:0.76,green:0.93,blue:0.46)
    var body: some View {
        ZStack {
            paper.ignoresSafeArea()
            VStack(spacing:0) {
                HStack {
                    Text("taphap").font(.system(size:24,weight:.heavy)).accessibilityLabel("TapHap")
                    Spacer()
                    if model.screen != "selection", !model.active {
                        Button { model.home() } label: {
                            Image(systemName:"square.grid.2x2").font(.system(size:22)).frame(width:48,height:44)
                        }.accessibilityLabel("Challenges").accessibilityIdentifier("home")
                    } else if !typeSize.isAccessibilitySize { Text("FIND YOUR INNER PULSE").font(.caption2.weight(.bold)).accessibilityHidden(true) }
                }.padding(.horizontal,24).padding(.vertical,16)
                if model.screen == "selection" { selection }
                else if model.screen == "play" { play }
                else { result }
            }
        }.foregroundStyle(ink).tint(ink)
    }
    private var selection: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                VStack(alignment:.leading,spacing:12) {
                    Text("When the music\ncomes back…").font(.largeTitle.weight(.bold)).fixedSize(horizontal:false,vertical:true)
                    Text("Will you still be on beat?").font(.title3)
                }
                VStack(alignment:.leading,spacing:18) {
                    HStack(alignment:.top) {
                        Image(systemName:"sun.horizon.fill").font(.system(size:44)).accessibilityHidden(true)
                        Spacer()
                        if !typeSize.isAccessibilitySize { Text("THE FIRST SONG").font(.caption.weight(.bold)) }
                    }
                    Text("Afterglow").font(.largeTitle.weight(.bold))
                    Text("Warm keys. A deep bassline. A groove you’ll have to carry yourself.").font(.body)
                    Text("Listen → keep playing in silence → meet the return").font(.subheadline.weight(.semibold))
                }.padding(24).frame(maxWidth:.infinity,alignment:.leading).background(accent,in:RoundedRectangle(cornerRadius:28))
                VStack(alignment:.leading,spacing:10) {
                    Text("How will you play?").font(.headline)
                    Picker("Input mode",selection:$model.mode) {
                        Text("Tap").tag(InputMode.tap); Text("Strum").tag(InputMode.strum)
                    }.pickerStyle(.segmented).accessibilityIdentifier("modePicker")
                    Text(model.mode == .tap ? "One finger. Tap the song’s steady pulse." : "Swipe down across the center string on each pulse. Lift between strokes.")
                        .font(.subheadline).fixedSize(horizontal:false,vertical:true)
                }
                VStack(alignment:.leading,spacing:12) {
                    Text(model.chapter).font(.title2.weight(.bold))
                    if let gap=model.reliableGap { Text(gap).font(.subheadline) }
                    Text("Start with three short baseline trials. Daily practice takes about four minutes: warm up, stretch twice, then focus on your next step. Retests use the same benchmark; transfer uses a separate song.").font(.subheadline)
                    primary(model.trainingActionTitle,id:"training") { model.beginTraining() }.disabled(!model.trainingAvailable)
                    if model.history.training.active(mode:model.mode) != nil {
                        Button("Restart this session from step one") { model.restartTraining() }.frame(minHeight:44)
                        Text("Restarting keeps all attempts in history. Only the new complete session counts.").font(.caption)
                    }
                    Text("A new chapter needs two strong practice days at the current level. Practice days use a fixed UTC calendar; opening the app earns nothing.").font(.caption)
                }.padding(20).background(.white.opacity(0.7),in:RoundedRectangle(cornerRadius:22))
                if !model.history.training.runs.filter({ $0.complete && $0.mode == model.mode }).isEmpty {
                    DisclosureGroup("Your training history") {
                        ForEach(model.history.training.runs.filter { $0.complete && $0.mode == model.mode }.reversed()) { run in
                            VStack(alignment:.leading,spacing:8) {
                                Text(run.kind.rawValue.capitalized).font(.headline)
                                Text(Date(timeIntervalSince1970:Double(run.day)*86400),style:.date).font(.caption)
                                Text(model.summary(for:run)).font(.subheadline)
                            }.padding(.vertical,8)
                        }
                    }.accessibilityIdentifier("trainingHistory")
                }
                #if DEBUG && targetEnvironment(simulator)
                if GameModel.uiFixture {
                    Text("SOFTWARE UI FIXTURE · not real training").font(.headline)
                    Button("Advance test day") { model.advanceFixtureDay() }.frame(minHeight:44).accessibilityIdentifier("advanceFixtureDay")
                }
                #endif
                Text("FREE PRACTICE").font(.caption.weight(.bold))
                if let catalog=model.catalog {
                    ForEach(Array(catalog.challenges.prefix(3).enumerated()),id:\.element.id) { index,challenge in
                        Button { model.choose(index) } label: {
                            HStack(spacing:16) {
                                Text(String(format:"%02d",index+1)).font(.title2.monospacedDigit().weight(.light))
                                VStack(alignment:.leading,spacing:5) {
                                    Text(challenge.title).font(.title3.weight(.bold))
                                    Text(challenge.subtitle).font(.subheadline)
                                }
                                Spacer(minLength:0)
                                Image(systemName:"arrow.up.right").accessibilityHidden(true)
                            }.padding(20).frame(maxWidth:.infinity,alignment:.leading)
                                .background(.white.opacity(0.7),in:RoundedRectangle(cornerRadius:22))
                        }.buttonStyle(.plain).accessibilityIdentifier("challenge-\(index)")
                    }
                }
                Text("Use your iPhone speaker. All music and results stay on this iPhone. No connection needed.").font(.footnote)
                if !model.history.trials.isEmpty {
                    DisclosureGroup("Recent attempts · \(model.history.trials.count)") {
                        ForEach(model.history.trials.suffix(8).reversed()) { trial in
                            VStack(alignment:.leading,spacing:4) {
                                Text(model.catalog?.challenges.first(where: { $0.id == trial.key.challenge })?.title ?? "Earlier challenge").font(.headline)
                                Text("\(trial.key.mode.rawValue.capitalized) · \(ResultCopy(trial.assessment).title)")
                                Text(trial.date,style:.date).font(.caption)
                            }.frame(maxWidth:.infinity,alignment:.leading).padding(.vertical,8)
                        }
                    }.accessibilityIdentifier("history")
                }
                messages
            }.padding(24)
        }
    }
    private var play: some View {
        GeometryReader { geo in
            if model.active {
                VStack(alignment:.leading,spacing:18) {
                    // Header has a fixed region: phase changes cannot move the crossing line.
                    ScrollView {
                        VStack(alignment:.leading,spacing:10) {
                            Text(stageTitle).font(.title.weight(.bold)).accessibilityIdentifier("stageTitle")
                            Text(stageMessage).font(.body)
                        }.frame(maxWidth:.infinity,alignment:.leading)
                    }.frame(height:geo.size.height*0.26)
                    GeometryReader { bar in
                        Capsule().fill(ink.opacity(0.12))
                        Capsule().fill(ink).frame(width:bar.size.width*model.session.progress)
                            .animation(reduceMotion ? nil : .linear(duration:1.0/30),value:model.session.progress)
                    }.frame(height:5).accessibilityHidden(true)
                    surface.frame(maxWidth:.infinity,maxHeight:.infinity)
                    Button("End attempt") { model.finish() }.frame(minHeight:44).accessibilityIdentifier("endAttempt")
                }.padding(24)
            } else {
                ScrollView {
                    VStack(alignment:.leading,spacing:18) {
                        Text(model.challenge?.title ?? "Afterglow").font(.subheadline.weight(.semibold))
                        if let run=model.currentTrainingRun {
                            Text("\(run.kind.rawValue.capitalized) · step \(run.trialIDs.count+1) of \(run.challenges.count)").font(.headline)
                        }
                        Text(model.challenge?.pattern == "spaced" ? "Play every other pulse: play, leave one, play, leave one. Keep that same spacing throughout the song." : "Play once on each steady pulse.").font(.body)
                        Toggle("I’m using outside timing help",isOn:$model.outsideHelp)
                        Text("Turn this on for a metronome, another player, or any timing cue. Assisted attempts are saved without training progress or records.").font(.caption)
                        Text(stageTitle).font(.largeTitle.weight(.bold)).fixedSize(horizontal:false,vertical:true)
                        Text(stageMessage).font(.body).fixedSize(horizontal:false,vertical:true)
                        surface.frame(height:260)
                        Text("Find the pulse as the song begins. Keep playing through the silence and until the song ends. There are no timing cues in the gap.").font(.subheadline)
                        primary("Start the song",id:"start") { model.start() }
                        messages
                    }.padding(24)
                }
            }
        }
    }
    private var surface: some View {
        GameInputSurface(model:model)
            .clipShape(RoundedRectangle(cornerRadius:28))
            .overlay(alignment:.bottom) {
                Text(model.mode == .tap ? "TAP · LIFT · REPEAT" : "STRUM DOWN · LIFT · REPEAT")
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .font(.caption.weight(.bold)).foregroundStyle(.white).padding(20).allowsHitTesting(false).accessibilityHidden(true)
            }
    }
    private var stageTitle: String {
        switch model.session.stage {
        case .ready,.result: return model.mode == .tap ? "Make the groove yours." : "Carry it on a string."
        case .preparing: return "Get comfortable."
        case .playing: return "Find the groove."
        case .warning: return "The song is about to disappear."
        case .silent: return "Carry the silence."
        case .returned: return "There it is. Keep going."
        }
    }
    private var stageMessage: String {
        switch model.session.stage {
        case .warning: return "Keep your own pulse when the sound fades."
        case .silent: return "Trust the rhythm you brought with you."
        case .returned: return "Meet the song where it is. Play through the ending."
        default: if model.challenge?.pattern == "spaced" { return "Play, leave one pulse, play, leave one. Keep the same spacing in silence." }; return model.mode == .tap ? "Tap with one finger, lifting on every pulse." : "Swipe downward across the center string. Lift, then begin above it again."
        }
    }
    private var result: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                Text("\(model.challenge?.songTitle.uppercased() ?? "SONG") · \(model.mode.rawValue.uppercased())").font(.caption.weight(.bold))
                if let trial=model.result {
                    if !model.canRetrySave, let reward=trial.reward, model.history.trials.contains(where: { $0.id == trial.id }) {
                        Text("\(reward.grade) · \(reward.stars) of 3 stars").font(.title2.weight(.bold))
                        if reward.perfectLanding { Text("Perfect landing").font(.headline) }
                        Text("Stars combine landing, consistency and drift. Three stars require all three within the tightest tolerances.").font(.caption)
                    }
                    if let run=model.currentTrainingRun { Text(model.summary(for:run)).font(.body).accessibilityIdentifier("trainingSummary") }
                    let copy=ResultCopy(trial.assessment)
                    Text(copy.title).font(.largeTitle.weight(.bold)).accessibilityIdentifier("resultTitle")
                    Text(copy.message).font(.title3)
                    if let score=trial.assessment.score {
                        VStack(alignment:.leading,spacing:12) {
                            Text("YOUR LANDING").font(.caption.weight(.bold))
                            Text("\(abs(score.reentryMS),specifier:"%.0f") ms \(score.reentryMS < 0 ? "early" : "late")")
                                .font(.largeTitle.weight(.bold))
                            Text("Compared with how you played before the silence.").font(.footnote)
                        }.padding(24).frame(maxWidth:.infinity,alignment:.leading).background(accent,in:RoundedRectangle(cornerRadius:24))
                        let comparison=model.comparison(for:trial)
                        if let headline=comparison.headline { Text(headline).font(.headline) }
                        if let previous=comparison.previous { Text(previous).font(.subheadline) }
                        DisclosureGroup("Understand this result") {
                            VStack(alignment:.leading,spacing:12) {
                                Text("Consistency: \(score.consistencyMS,specifier:"%.1f") ms of variation around your timing trend. Lower is more even.")
                                Text("Drift: \(abs(score.tempoDriftMSPerBeat),specifier:"%.1f") ms \(score.tempoDriftMSPerBeat < 0 ? "faster" : "slower") per pulse than your opening.")
                                Text("A closest landing measures the return only. It doesn’t rank your overall musicianship.")
                            }.padding(.top,12)
                        }
                    } else {
                        Text("Landing unavailable").font(.title2.weight(.bold))
                        if let intervals=trial.assessment.observedIntervals {
                            DisclosureGroup("What we could measure") {
                                Text("Observed spacing in silence: \(intervals.medianSpacingMS,specifier:"%.0f") ms median. Variation: \(intervals.intervalSDMS,specifier:"%.0f") ms. These describe captured inputs; they don’t identify missed beats.").padding(.top,12)
                            }
                        }
                    }
                } else { Text("The song couldn’t start.").font(.largeTitle.weight(.bold)) }
                messages
                if let run=model.currentTrainingRun {
                    primary(run.complete ? "Back to your training" : "Continue session",id:"continueTraining") { model.continueTraining() }.disabled(model.canRetrySave)
                } else {
                    primary("Play it again",id:"retry") { model.retry() }
                    Button("Next challenge →") { model.next() }.font(.headline).frame(maxWidth:.infinity,minHeight:48).accessibilityIdentifier("next")
                }
            }.padding(24)
        }.accessibilityIdentifier("resultScreen")
    }
    private var messages: some View {
        VStack(alignment:.leading,spacing:8) {
            if let message=model.errorMessage { Text(message).font(.body).accessibilityIdentifier("errorMessage") }
            if let message=model.storageMessage {
                Text(message).font(.body).accessibilityIdentifier("storageMessage")
                if model.canRetrySave { Button("Save again") { model.retrySave() }.frame(minHeight:44) }
            }
        }
    }
    private func primary(_ title: String,id: String,action: @escaping () -> Void) -> some View {
        Button(action:action) { Text(title).font(.headline).frame(maxWidth:.infinity,minHeight:54).padding(.horizontal,12) }
            .buttonStyle(.plain).background(ink,in:RoundedRectangle(cornerRadius:18)).foregroundStyle(.white).accessibilityIdentifier(id)
    }
}

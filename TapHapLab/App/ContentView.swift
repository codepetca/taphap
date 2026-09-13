import MusicKit
import SwiftUI

struct ContentView: View {
    @StateObject private var model = LabViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    purposeCard
                    sourcePicker

                    if model.source == .reference {
                        referenceCard
                    } else {
                        AppleMusicPanel(model: model, music: model.appleMusic)
                    }

                    if model.phase != .idle {
                        exerciseCard
                    }

                    if let result = model.result {
                        resultCard(result)
                    }

                    if !model.eventLog.isEmpty {
                        diagnosticsCard
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("TapHap Lab")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var purposeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Phase 1 feasibility test")
                .font(.headline)
            Text("Tap with audible music, keep tapping through one silent gap, then inspect timing and audio diagnostics. Apple Music gaps use pause, playhead advance, and resume. This is a test instrument, not the finished app.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .labCard()
    }

    private var sourcePicker: some View {
        Picker("Audio source", selection: Binding(
            get: { model.source },
            set: { model.selectSource($0) }
        )) {
            ForEach(LabAudioSource.allCases) { source in
                Text(source.rawValue).tag(source)
            }
        }
        .pickerStyle(.segmented)
    }

    private var referenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Known 120 BPM reference")
                .font(.headline)
            Text("Use this first. It provides a controlled beat grid so stable route and touch latency can be separated from actual drift.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                model.startReference()
            } label: {
                Label("Start reference click", systemImage: "metronome")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .labCard()
    }

    private var exerciseCard: some View {
        VStack(spacing: 16) {
            Text(model.statusMessage)
                .font(.headline)
                .multilineTextAlignment(.center)

            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: model.phase != .silentGap)) { _ in
                let progress = model.gapProgress(at: MonotonicClock.now)
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.10))
                    Circle()
                        .stroke(Color.accentColor.opacity(0.18), lineWidth: 12)

                    if model.phase == .silentGap {
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                Color.accentColor,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                    }

                    TapCaptureView(onTap: model.recordTap)

                    VStack(spacing: 5) {
                        Image(systemName: model.phase == .silentGap ? "speaker.slash.fill" : "hand.tap.fill")
                            .font(.system(size: 34, weight: .semibold))
                        Text(model.phase == .silentGap ? "KEEP TAPPING" : "TAP HERE")
                            .font(.headline.monospaced())
                        Text("touch down is timestamped")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .allowsHitTesting(false)
                }
                .frame(width: 250, height: 250)
            }

            HStack(spacing: 12) {
                metric(
                    title: "Taps",
                    value: "\(model.session.audibleTaps.count)",
                    detail: "audible"
                )
                metric(
                    title: "Estimate",
                    value: model.pulse.map { String(format: "%.1f", $0.bpm) } ?? "—",
                    detail: "BPM"
                )
                metric(
                    title: "Jitter",
                    value: model.pulse.map { String(format: "%.0f", $0.residualJitter * 1_000) } ?? "—",
                    detail: "ms"
                )
            }

            if let grid = model.knownGridDiagnostics {
                Text(String(
                    format: "Known-grid baseline: %+.0f ms mean offset, %.0f ms jitter",
                    grid.meanOffsetMilliseconds,
                    grid.jitterMilliseconds
                ))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            }

            if model.phase == .calibrating, model.pulse != nil {
                Button("Start one 8-beat silent gap") {
                    model.startGap()
                }
                .buttonStyle(.borderedProminent)
            }

            if model.phase == .result {
                Button("Try again") {
                    model.resetExercise()
                }
                .buttonStyle(.bordered)
            }
        }
        .labCard()
    }

    private func resultCard(_ result: GapScore) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercise result")
                .font(.headline)
            Text(result.endSummary)
                .font(.system(.title2, design: .rounded, weight: .bold))
            Text(result.direction.capitalized)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                metric(
                    title: "Mean error",
                    value: String(format: "%.0f", result.meanAbsoluteErrorMilliseconds),
                    detail: "ms"
                )
                metric(
                    title: "Consistency",
                    value: String(format: "%.0f", result.consistencyMilliseconds),
                    detail: "ms"
                )
                metric(
                    title: "Slope",
                    value: String(format: "%+.1f", result.tempoSlopeMillisecondsPerSecond),
                    detail: "ms/s"
                )
            }

            if let advance = model.musicPlayheadAdvance, let error = model.musicPlayheadError {
                Divider()
                Text(String(
                    format: "Apple Music seek/resume advanced %.3f s; difference from the scheduled gap: %+.1f ms",
                    advance,
                    error * 1_000
                ))
                .font(.caption.monospacedDigit())
            }
        }
        .labCard()
    }

    private var diagnosticsCard: some View {
        DisclosureGroup("Technical diagnostics") {
            VStack(alignment: .leading, spacing: 8) {
                ShareLink(item: model.eventLog.reversed().joined(separator: "\n")) {
                    Label("Share diagnostics", systemImage: "square.and.arrow.up")
                }
                .font(.caption)

                ForEach(Array(model.eventLog.enumerated()), id: \.offset) { _, event in
                    Text(event)
                        .font(.caption2.monospaced())
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, 10)
        }
        .labCard()
    }

    private func metric(title: String, value: String, detail: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct AppleMusicPanel: View {
    @ObservedObject var model: LabViewModel
    @ObservedObject var music: AppleMusicController
    @State private var searchTerm = ""
    @FocusState private var searchFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Apple Music pause/skip/resume test")
                .font(.headline)
            Text(music.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if music.authorizationStatus != .authorized || !music.canPlayCatalogContent {
                Button("Connect Apple Music") {
                    Task { await music.requestAccess() }
                }
                .buttonStyle(.borderedProminent)
            } else {
                HStack {
                    TextField("Search songs", text: $searchTerm)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.search)
                        .focused($searchFieldFocused)
                        .onSubmit {
                            searchFieldFocused = false
                            Task { await music.search(for: searchTerm) }
                        }
                    Button("Search") {
                        searchFieldFocused = false
                        Task { await music.search(for: searchTerm) }
                    }
                    .buttonStyle(.bordered)
                }

                if let song = music.selectedSong {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(song.title).font(.subheadline.weight(.semibold))
                            Text(song.artistName).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(music.isPlaying ? "Pause" : "Play") {
                            Task { await music.togglePlayback() }
                        }
                        .buttonStyle(.bordered)
                    }
                    Text(String(format: "Player time %.1f s", music.playbackTime))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                ForEach(music.searchResults) { song in
                    Button {
                        searchFieldFocused = false
                        Task { await model.playAppleMusic(song) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(song.title)
                                    .foregroundStyle(.primary)
                                Text(song.artistName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "play.fill")
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
        }
        .labCard()
    }
}

private extension View {
    func labCard() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

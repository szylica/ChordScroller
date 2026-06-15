import SwiftUI

struct SongDetailView: View {
    @ObservedObject var store: SongStore
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State var song: Song
    @State private var showingEditor        = false
    @State private var showingTeleprompter  = false
    @State private var showingDeleteAlert   = false
    @State private var selectedChordPopup: String?
    @Environment(\.dismiss)     private var dismiss
    @Environment(\.colorScheme) private var systemColorScheme

    // MARK: - Odroczone ładowanie

    @State private var chordsInSong:  [String] = []
    @State private var isContentReady = false

    // MARK: - Computed helpers

    private var effectiveScheme: ColorScheme {
        AppTheme.resolveColorScheme(
            appScheme:    settingsManager.settings.colorScheme,
            systemScheme: systemColorScheme
        )
    }

    private var lang: AppLanguage { settingsManager.resolvedLanguage }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppTheme.background(for: effectiveScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    tagsSection

                    metadataCard

                    if isContentReady && !chordsInSong.isEmpty {
                        ChordsPanelView(chords: chordsInSong)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if isContentReady {
                        FormattedSongView(
                            content:  song.content,
                            fontSize: song.fontSize * 0.85,
                            onChordTap: { chord in
                                withAnimation(.easeOut(duration: 0.2)) {
                                    selectedChordPopup = chord
                                }
                            }
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.cardBackground(for: effectiveScheme))
                        )
                        .transition(.opacity)
                    } else {
                        contentSkeleton
                    }
                }
                .padding(16)
                .padding(.bottom, 100)
            }

            playButton

            if let chord = selectedChordPopup {
                ChordPopupView(chordName: chord) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedChordPopup = nil
                    }
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .navigationTitle(song.title.isEmpty ? L10n.untitled.localized(for: lang) : song.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { exportPDF() } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.orange)
                }
                Button { showingEditor = true } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(.orange)
                }
                Button(role: .destructive) { showingDeleteAlert = true } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            EditorView(store: store, song: song) { updated in
                song = updated
                Task { await parseContent() }
            }
        }
        .fullScreenCover(isPresented: $showingTeleprompter) {
            TeleprompterView(song: song)
        }
        .alert(L10n.deleteSong.localized(for: lang), isPresented: $showingDeleteAlert) {
            Button(L10n.deleteSongConfirm.localized(for: lang), role: .destructive) {
                store.delete(song)
                dismiss()
            }
            Button(L10n.cancel.localized(for: lang), role: .cancel) {}
        } message: {
            Text(L10n.cannotUndo.localized(for: lang))
        }
        .task {
            await parseContent()
        }
    }

    // MARK: - Asynchroniczne parsowanie

    private func parseContent() async {
        let chords = await Task.detached(priority: .userInitiated) {
            ChordDatabase.extractChords(from: song.content)
        }.value

        await MainActor.run {
            withAnimation(.easeOut(duration: 0.15)) {
                self.chordsInSong  = chords
                self.isContentReady = true
            }
        }
    }

    // MARK: - Skeleton loader

    private var contentSkeleton: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.secondaryText(for: effectiveScheme).opacity(0.15))
                    .frame(height: 16)
                    .frame(maxWidth: skeletonWidth(for: index))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardBackground(for: effectiveScheme))
        )
        .shimmering()
    }

    private func skeletonWidth(for index: Int) -> CGFloat {
        let widths: [CGFloat] = [0.9, 0.7, 0.85, 0.6, 0.95, 0.75, 0.8, 0.5]
        return UIScreen.main.bounds.width * widths[index % widths.count]
    }

    // MARK: - Subviews

    @ViewBuilder
    private var tagsSection: some View {
        if !song.tags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(song.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(AppTheme.chordButtonBackground(for: effectiveScheme))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    private var metadataCard: some View {
        HStack(spacing: 0) {
            MetadataCell(
                label: L10n.tempo.localized(for: lang),
                value: "\(Int(song.scrollSpeed)) px/s",
                effectiveScheme: effectiveScheme
            )

            MetadataDivider(effectiveScheme: effectiveScheme)

            MetadataCell(
                label: L10n.fontSize.localized(for: lang),
                value: "\(Int(song.fontSize)) pt",
                effectiveScheme: effectiveScheme
            )

            MetadataDivider(effectiveScheme: effectiveScheme)

            MetadataCell(
                label: L10n.capo.localized(for: lang),
                value: song.capoDisplayText,
                effectiveScheme: effectiveScheme
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardBackground(for: effectiveScheme))
        )
    }

    private var playButton: some View {
        VStack {
            Spacer()
            Button {
                showingTeleprompter = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                    Text(L10n.playTeleprompter.localized(for: lang))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.orange)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Eksport PDF

    private func exportPDF() {
        let data = PDFExporter.generatePDF(for: song)

        let sanitizedTitle = song.title
            .replacingOccurrences(of: "[/\\\\:*?\"<>|]", with: "_", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        let fileName = sanitizedTitle.isEmpty
            ? L10n.untitled.localized(for: lang)
            : sanitizedTitle
        let fullName = "\(fileName) - ChordScroller.pdf"

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fullName)
        try? data.write(to: tempURL)

        presentShareSheet(with: tempURL)
    }

    private func presentShareSheet(with url: URL) {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = windowScene.windows.first?.rootViewController
        else { return }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        topVC.present(activityVC, animated: true)
    }
}

// MARK: - Komórka metadanych

private struct MetadataCell: View {
    let label:          String
    let value:          String
    let effectiveScheme: ColorScheme

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText(for: effectiveScheme))
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.orange)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Separator metadanych

private struct MetadataDivider: View {
    let effectiveScheme: ColorScheme

    var body: some View {
        Rectangle()
            .fill(AppTheme.separator(for: effectiveScheme))
            .frame(width: 1, height: 32)
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.2), .clear],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                    .frame(width: geometry.size.width * 0.6)
                    .offset(x: -geometry.size.width * 0.3 + phase * geometry.size.width * 1.6)
                }
            )
            .clipped()
            .onAppear {
                withAnimation(
                    .linear(duration: 1.2)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}
    
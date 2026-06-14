import SwiftUI

struct SongDetailView: View {
    @ObservedObject var store: SongStore
    @State var song: Song
    @State private var showingEditor = false
    @State private var showingTeleprompter = false
    @State private var showingDeleteAlert = false
    @State private var selectedChordPopup: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Odroczone ładowanie
    
    @State private var chordsInSong: [String] = []
    @State private var isContentReady = false

    var body: some View {
        ZStack {
            AppTheme.background(for: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Tagi — lekkie, renderują się natychmiast
                    tagsSection
                    
                    // Metadata — lekkie, renderują się natychmiast
                    metadataCard
                    
                    // Panel akordów — czeka na parsowanie
                    if isContentReady && !chordsInSong.isEmpty {
                        ChordsPanelView(chords: chordsInSong)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Treść piosenki — czeka na parsowanie lub pokazuje skeleton
                    if isContentReady {
                        FormattedSongView(
                            content: song.content,
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
                                .fill(AppTheme.cardBackground(for: colorScheme))
                        )
                        .transition(.opacity)
                    } else {
                        contentSkeleton
                    }
                }
                .padding(16)
                .padding(.bottom, 100)
            }

            // Przycisk PLAY
            playButton
            
            // Popup z akordem
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
        .navigationTitle(song.title.isEmpty ? "Bez tytułu" : song.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { exportPDF() } label: {
                    Image(systemName: "square.and.arrow.up").foregroundStyle(.orange)
                }
                Button { showingEditor = true } label: {
                    Image(systemName: "pencil").foregroundStyle(.orange)
                }
                Button(role: .destructive) { showingDeleteAlert = true } label: {
                    Image(systemName: "trash").foregroundStyle(.red)
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            EditorView(store: store, song: song) { updated in
                song = updated
                // Odśwież po edycji
                Task { await parseContent() }
            }
        }
        .fullScreenCover(isPresented: $showingTeleprompter) {
            TeleprompterView(song: song)
        }
        .alert("Usuń piosenkę?", isPresented: $showingDeleteAlert) {
            Button("Usuń", role: .destructive) { store.delete(song); dismiss() }
            Button("Anuluj", role: .cancel) {}
        } message: {
            Text("Tej operacji nie można cofnąć.")
        }
        .task {
            await parseContent()
        }
    }
    
    // MARK: - Asynchroniczne parsowanie
    
    private func parseContent() async {
        // Wykonaj ciężkie operacje poza main thread
        let chords = await Task.detached(priority: .userInitiated) {
            ChordDatabase.extractChords(from: song.content)
        }.value
        
        // Aktualizuj UI na main thread
        await MainActor.run {
            withAnimation(.easeOut(duration: 0.15)) {
                self.chordsInSong = chords
                self.isContentReady = true
            }
        }
    }
    
    // MARK: - Skeleton loader
    
    private var contentSkeleton: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.secondaryText(for: colorScheme).opacity(0.15))
                    .frame(height: 16)
                    .frame(maxWidth: skeletonWidth(for: index))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardBackground(for: colorScheme))
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
                                    .fill(AppTheme.chordButtonBackground(for: colorScheme))
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
            VStack(spacing: 4) {
                Text("Tempo")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                Text("\(Int(song.scrollSpeed)) px/s")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
            }
            .frame(maxWidth: .infinity)
            
            Rectangle()
                .fill(AppTheme.separator(for: colorScheme))
                .frame(width: 1, height: 32)
            
            VStack(spacing: 4) {
                Text("Czcionka")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                Text("\(Int(song.fontSize)) pt")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
            }
            .frame(maxWidth: .infinity)
            
            Rectangle()
                .fill(AppTheme.separator(for: colorScheme))
                .frame(width: 1, height: 32)
            
            VStack(spacing: 4) {
                Text("Kapodaster")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                Text(song.capoDisplayText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardBackground(for: colorScheme))
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
                    Text("Odtwórz teleprompter")
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
        let fileName = sanitizedTitle.isEmpty ? "Bez tytulu" : sanitizedTitle
        let fullName = "\(fileName) - ChordScroller.pdf"
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fullName)
        try? data.write(to: tempURL)
        
        presentShareSheet(with: tempURL)
    }
    
    private func presentShareSheet(with url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        
        topVC.present(activityVC, animated: true)
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
                        colors: [
                            .clear,
                            .white.opacity(0.2),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
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

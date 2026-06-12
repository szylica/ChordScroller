import SwiftUI

struct SongDetailView: View {
    @ObservedObject var store: SongStore
    @State var song: Song
    @State private var showingEditor = false
    @State private var showingTeleprompter = false
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var selectedChordPopup: String?
    @State private var pdfURL: URL?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private var chordsInSong: [String] {
        ChordDatabase.extractChords(from: song.content)
    }

    var body: some View {
        ZStack {
            AppTheme.background(for: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Tagi
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
                    
                    // Metadata
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
                    
                    // Panel akordów
                    if !chordsInSong.isEmpty {
                        ChordsPanelView(chords: chordsInSong)
                    }

                    // Treść piosenki
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
                }
                .padding(16)
                .padding(.bottom, 100)
            }

            // Przycisk PLAY
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
            EditorView(store: store, song: song) { updated in song = updated }
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
        .sheet(isPresented: $showingShareSheet) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    private func exportPDF() {
        let data = PDFExporter.generatePDF(for: song)
        
        // Zapisz do pliku tymczasowego z nazwą piosenki
        let sanitizedTitle = song.title
            .replacingOccurrences(of: "[/\\\\:*?\"<>|]", with: "_", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        let fileName = sanitizedTitle.isEmpty ? "Bez tytulu" : sanitizedTitle
        let fullName = "\(fileName) - ChordScroller.pdf"
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fullName)
        try? data.write(to: tempURL)
        
        self.pdfURL = tempURL
        self.showingShareSheet = true
    }
}

// MARK: - Share Sheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

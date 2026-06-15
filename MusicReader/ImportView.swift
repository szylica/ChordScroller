import SwiftUI

struct ImportView: View {
    @ObservedObject var store: SongStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var urlText = ""
    @State private var importState: ImportState = .idle
    @State private var urlToLoad: String? = nil

    enum ImportState {
        case idle, loading
        case success(Song)
        case error(String)
    }

    private var isLoading: Bool {
        if case .loading = importState { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Nagłówek
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.orange)
                            Text(L10n.importSongTitle.localized())
                                .font(.title2).fontWeight(.bold)
                                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                            Text(L10n.supportedSites.localized())
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                            
                            HStack(spacing: 16) {
                                SupportedSiteBadge(name: "Wywrota.pl", icon: "🎸", colorScheme: colorScheme)
                                SupportedSiteBadge(name: "Ultimate Guitar", icon: "🎵", colorScheme: colorScheme)
                            }
                        }
                        .padding(.top, 8)

                        // Pole URL
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.pasteLink.localized())
                                .font(.caption).fontWeight(.semibold)
                                .foregroundStyle(.orange)

                            HStack(spacing: 10) {
                                Image(systemName: "link")
                                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                                TextField(L10n.urlPlaceholder.localized(), text: $urlText)
                                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                    .keyboardType(.URL)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .onSubmit { startImport() }
                                
                                Button {
                                    if let clipboard = UIPasteboard.general.string {
                                        urlText = clipboard
                                    }
                                } label: {
                                    Image(systemName: "doc.on.clipboard")
                                        .foregroundStyle(.orange)
                                }
                                
                                if !urlText.isEmpty {
                                    Button { urlText = "" } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                                    }
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.inputBackground(for: colorScheme))
                            )

                            VStack(alignment: .leading, spacing: 6) {
                                Text(L10n.examples.localized())
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                                
                                ExampleURLView(url: L10n.exampleURLWywrota.localized(), description: "Wywrota", colorScheme: colorScheme)
                                ExampleURLView(url: L10n.exampleURLUG.localized(), description: "Ultimate Guitar (Chords)", colorScheme: colorScheme)
                            }
                        }

                        // Przycisk importu
                        Button { startImport() } label: {
                            HStack(spacing: 10) {
                                if isLoading {
                                    ProgressView().tint(.black).scaleEffect(0.85)
                                } else {
                                    Image(systemName: "arrow.down.circle")
                                }
                                Text(isLoading ? L10n.importing.localized() : L10n.importButton.localized())
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(urlText.isEmpty || isLoading
                                          ? Color.orange.opacity(0.4)
                                          : Color.orange)
                            )
                        }
                        .disabled(urlText.isEmpty || isLoading)

                        switch importState {
                        case .error(let msg):
                            ErrorCard(message: msg)
                            
                        case .success(let song):
                            SongImportPreviewCard(song: song, colorScheme: colorScheme) {
                                store.add(song)
                                dismiss()
                            }
                            
                        default:
                            EmptyView()
                        }
                        
                        TipsView(colorScheme: colorScheme)
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.cancel.localized()) { dismiss() }
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                }
            }
            .overlay(
                SongImporterView(urlToLoad: $urlToLoad) { result in
                    urlToLoad = nil
                    switch result {
                    case .success(let song):
                        withAnimation { importState = .success(song) }
                    case .failure(let err):
                        withAnimation { importState = .error(err.localizedDescription) }
                    }
                }
                .frame(width: 1, height: 1)
                .opacity(0.001)
                .allowsHitTesting(false)
            )
        }
    }

    private func startImport() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        var url = urlText.trimmingCharacters(in: .whitespaces)
        if !url.hasPrefix("http://") && !url.hasPrefix("https://") {
            url = "https://" + url
        }
        
        guard url.hasPrefix("http") else {
            importState = .error(L10n.invalidURL.localized())
            return
        }
        
        let isWywrota = url.contains("wywrota.pl")
        let isUG = url.contains("ultimate-guitar.com") || url.contains("ultimateguitar.com")
        
        guard isWywrota || isUG else {
            importState = .error(L10n.unsupportedSite.localized())
            return
        }
        
        importState = .loading
        urlToLoad = url
    }
}

// MARK: - Komponenty UI

struct SupportedSiteBadge: View {
    let name: String
    let icon: String
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 6) {
            Text(icon)
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(AppTheme.primaryText(for: colorScheme).opacity(0.8))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(AppTheme.cardBackground(for: colorScheme))
        )
    }
}

struct ExampleURLView: View {
    let url: String
    let description: String
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 6) {
            Text("•").foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            Text(url).font(.caption2).foregroundStyle(AppTheme.secondaryText(for: colorScheme).opacity(0.8))
            Text("(\(description))").font(.caption2).foregroundStyle(AppTheme.secondaryText(for: colorScheme).opacity(0.6))
        }
    }
}

struct ErrorCard: View {
    let message: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red).font(.title3)
            Text(message).font(.subheadline).foregroundStyle(.red.opacity(0.9)).fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.1)))
    }
}

struct SongImportPreviewCard: View {
    let song: Song
    let colorScheme: ColorScheme
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.title3)
                Text(L10n.found.localized()).fontWeight(.semibold).foregroundStyle(.green)
                Spacer()
            }
            
            Text(song.title).font(.headline).foregroundStyle(AppTheme.primaryText(for: colorScheme)).lineLimit(2)
            
            ScrollView {
                Text(String(song.content.prefix(500)) + (song.content.count > 500 ? "\n…" : ""))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 160)
            
            HStack(spacing: 16) {
                let lineCount = song.content.components(separatedBy: "\n").count
                Label(L10n.linesCount(lineCount), systemImage: "text.alignleft")
                if let capo = song.capo {
                    Label(L10n.capoValue(capo), systemImage: "guitars")
                }
            }
            .font(.caption)
            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            
            Button(action: onSave) {
                Label(L10n.addToLibrary.localized(), systemImage: "plus.circle.fill")
                    .fontWeight(.semibold).foregroundStyle(.black)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color(red: 0.10, green: 0.14, blue: 0.10) : Color(red: 0.92, green: 0.97, blue: 0.92))
        )
    }
}

struct TipsView: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.tips.localized(), systemImage: "lightbulb")
                .font(.caption).fontWeight(.semibold).foregroundStyle(.orange.opacity(0.8))
            
            VStack(alignment: .leading, spacing: 8) {
                TipRow(icon: "hand.tap", text: L10n.tipUGChords.localized(), colorScheme: colorScheme)
                TipRow(icon: "star", text: L10n.tipHighRating.localized(), colorScheme: colorScheme)
                TipRow(icon: "pencil", text: L10n.tipEditAfterImport.localized(), colorScheme: colorScheme)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(AppTheme.cardBackground(for: colorScheme))
        )
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).font(.caption).foregroundStyle(.orange.opacity(0.6)).frame(width: 16)
            Text(text).font(.caption).foregroundStyle(AppTheme.secondaryText(for: colorScheme))
        }
    }
}

import SwiftUI

struct EditorView: View {
    @ObservedObject var store: SongStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var existingSong: Song?
    var onSave: ((Song) -> Void)?

    @State private var title: String
    @State private var content: String
    @State private var scrollSpeed: Double
    @State private var fontSize: Double
    @State private var capo: Int
    @State private var tags: [String]
    @State private var newTagText: String = ""
    @State private var showingPreview = false

    init(store: SongStore, song: Song?, onSave: ((Song) -> Void)? = nil) {
        self.store = store
        self.existingSong = song
        self.onSave = onSave
        _title = State(initialValue: song?.title ?? "")
        _content = State(initialValue: song?.content ?? "")
        _scrollSpeed = State(initialValue: song?.scrollSpeed ?? 40)
        _fontSize = State(initialValue: song?.fontSize ?? 22)
        _capo = State(initialValue: song?.capo ?? 0)
        _tags = State(initialValue: song?.tags ?? [])
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Tytuł
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Tytuł", systemImage: "music.note")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)

                            TextField("Nazwa piosenki…", text: $title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AppTheme.inputBackground(for: colorScheme))
                                )
                        }
                        
                        // Tagi
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Tagi", systemImage: "tag")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                            
                            // Aktualne tagi
                            if !tags.isEmpty {
                                FlowLayoutTags {
                                    ForEach(tags, id: \.self) { tag in
                                        HStack(spacing: 4) {
                                            Text(tag)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(.orange)
                                            
                                            Button {
                                                withAnimation { tags.removeAll { $0 == tag } }
                                            } label: {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundStyle(.orange.opacity(0.6))
                                            }
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
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
                            
                            // Dodaj tag
                            HStack(spacing: 8) {
                                TextField("Nowy tag…", text: $newTagText)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(AppTheme.inputBackground(for: colorScheme))
                                    )
                                    .onSubmit { addTag() }
                                
                                Button {
                                    addTag()
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.black)
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(newTagText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.orange.opacity(0.4) : Color.orange)
                                        )
                                }
                                .disabled(newTagText.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            
                            // Istniejące tagi jako sugestie
                            let suggestions = store.allTags.filter { !tags.contains($0) }
                            if !suggestions.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Istniejące tagi:")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 6) {
                                            ForEach(suggestions, id: \.self) { tag in
                                                Button {
                                                    withAnimation { tags.append(tag) }
                                                } label: {
                                                    Text("+ \(tag)")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 5)
                                                        .background(
                                                            Capsule()
                                                                .stroke(AppTheme.separator(for: colorScheme), lineWidth: 1)
                                                        )
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Kapodaster
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Kapodaster", systemImage: "guitars")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                                Spacer()
                                Text(capo == 0 ? "Brak" : "\(capo). próg")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.orange)
                                    .monospacedDigit()
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    CapoButton(value: 0, label: "Brak", selected: capo == 0, colorScheme: colorScheme) {
                                        withAnimation { capo = 0 }
                                    }
                                    ForEach(1...12, id: \.self) { fret in
                                        CapoButton(value: fret, label: "\(fret)", selected: capo == fret, colorScheme: colorScheme) {
                                            withAnimation { capo = fret }
                                        }
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }

                        // Slajder tempa
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Tempo przewijania", systemImage: "gauge.with.dots.needle.bottom.50percent")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                                Spacer()
                                Text("\(Int(scrollSpeed)) px/s")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                    .monospacedDigit()
                            }

                            HStack {
                                Text("Wolno")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                                Slider(value: $scrollSpeed, in: 10...200, step: 5)
                                    .tint(.orange)
                                Text("Szybko")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                            }

                            HStack(spacing: 8) {
                                ForEach([("Wolno", 20.0), ("Średnio", 50.0), ("Szybko", 90.0), ("Bardzo szybko", 140.0)], id: \.0) { label, speed in
                                    Button {
                                        withAnimation { scrollSpeed = speed }
                                    } label: {
                                        Text(label)
                                            .font(.caption2)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(scrollSpeed == speed ? Color.orange : AppTheme.inactiveButton(for: colorScheme))
                                            )
                                            .foregroundStyle(scrollSpeed == speed ? .black : AppTheme.secondaryText(for: colorScheme))
                                    }
                                }
                            }
                        }

                        // Slajder czcionki
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Rozmiar czcionki", systemImage: "textformat.size")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                                Spacer()
                                Text("\(Int(fontSize)) pt")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                    .monospacedDigit()
                            }

                            HStack {
                                Text("Małe")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                                Slider(value: $fontSize, in: 12...48, step: 1)
                                    .tint(.orange)
                                Text("Duże")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                            }
                        }

                        // Edytor tekstu
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Tekst i akordy", systemImage: "text.alignleft")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                                Spacer()
                                Text("Akordy w [nawiasach]")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                            }

                            TextEditor(text: $content)
                                .font(.system(size: 16, design: .monospaced))
                                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 320)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AppTheme.inputBackground(for: colorScheme))
                                )

                            QuickChordsView(content: $content)
                        }

                        // Przycisk podglądu
                        Button {
                            showingPreview = true
                        } label: {
                            Label("Podgląd przewijania", systemImage: "eye")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange, lineWidth: 1.5)
                                )
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(existingSong == nil ? "Nowa piosenka" : "Edytuj")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Anuluj") { dismiss() }
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Zapisz") {
                        saveSong()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty && content.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .fullScreenCover(isPresented: $showingPreview) {
                TeleprompterView(song: currentSong)
            }
        }
    }
    
    private func addTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        withAnimation { tags.append(trimmed) }
        newTagText = ""
    }

    private var currentSong: Song {
        var s = existingSong ?? Song()
        s.title = title
        s.content = content
        s.scrollSpeed = scrollSpeed
        s.fontSize = fontSize
        s.capo = capo > 0 ? capo : nil
        s.tags = tags
        return s
    }

    private func saveSong() {
        var song = currentSong
        if song.title.trimmingCharacters(in: .whitespaces).isEmpty {
            song.title = "Bez tytułu"
        }
        if existingSong != nil {
            store.update(song)
            onSave?(song)
        } else {
            store.add(song)
        }
        dismiss()
    }
}

// MARK: - FlowLayout dla tagów

struct FlowLayoutTags: Layout {
    var spacing: CGFloat = 6
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, pos) in result.positions.enumerated() where index < subviews.count {
            subviews[index].place(at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y), proposal: .unspecified)
        }
    }
    
    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? 10000
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        
        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

// MARK: - Przycisk wyboru capo

struct CapoButton: View {
    let value: Int
    let label: String
    let selected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .frame(minWidth: value == 0 ? 50 : 36)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selected ? Color.orange : AppTheme.inactiveButton(for: colorScheme))
                )
                .foregroundStyle(selected ? .black : AppTheme.secondaryText(for: colorScheme))
        }
    }
}

// MARK: - Panel szybkiego wstawiania akordów

struct QuickChordsView: View {
    @Binding var content: String
    @Environment(\.colorScheme) private var colorScheme

    let commonChords = ["Am", "Em", "Dm", "Gm", "C", "G", "D", "F", "E", "A", "Bm", "F#m"]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Szybkie wstawianie")
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(commonChords, id: \.self) { chord in
                        Button {
                            content += "[\(chord)]"
                        } label: {
                            Text(chord)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(AppTheme.chordButtonBackground(for: colorScheme))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                                        )
                                )
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

import SwiftUI

struct ContentView: View {
    @StateObject private var store = SongStore()
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State private var showingNewSong    = false
    @State private var showingImport     = false
    @State private var showingSettings   = false
    @State private var showingTuner      = false
    @State private var showingMenu       = false
    @State private var searchText        = ""
    @State private var selectedTag: String? = nil
    @Environment(\.colorScheme) private var systemColorScheme

    // MARK: - Computed helpers

    private var effectiveScheme: ColorScheme {
        AppTheme.resolveColorScheme(
            appScheme:    settingsManager.settings.colorScheme,
            systemScheme: systemColorScheme
        )
    }

    private var lang: AppLanguage { settingsManager.resolvedLanguage }

    var filteredSongs: [Song] {
        var result = store.songs

        if let tag = selectedTag {
            result = result.filter { $0.tags.contains(tag) }
        }

        if !searchText.isEmpty {
            result = store.songs.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }

        return result
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    AppTheme.background(for: effectiveScheme)
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        if !store.allTags.isEmpty && searchText.isEmpty {
                            TagFilterBar(
                                tags:        store.allTags,
                                selectedTag: $selectedTag,
                                songCounts:  tagCounts,
                                colorScheme: effectiveScheme,
                                lang:        lang
                            )
                        }

                        if store.songs.isEmpty {
                            Spacer()
                            emptyState
                            Spacer()
                        } else if filteredSongs.isEmpty {
                            Spacer()
                            noResultsState
                            Spacer()
                        } else {
                            songList
                        }
                    }

                    EdgeSwipeArea {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showingMenu = true
                        }
                    }
                }
                .navigationTitle(L10n.library.localized(for: lang))
                .navigationBarTitleDisplayMode(.large)
                .searchable(text: $searchText, prompt: L10n.searchSongs.localized(for: lang))
                .navigationDestination(for: Song.ID.self) { songID in
                    if let song = store.songs.first(where: { $0.id == songID }) {
                        SongDetailView(store: store, song: song)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack(spacing: 16) {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    showingMenu = true
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal")
                                    .font(.title3)
                                    .foregroundStyle(.orange)
                            }

                            Button {
                                showingImport = true
                            } label: {
                                Image(systemName: "arrow.down.circle")
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingNewSong = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .sheet(isPresented: $showingNewSong) {
                    EditorView(store: store, song: nil)
                        .preferredColorScheme(settingsManager.settings.colorScheme.colorScheme)
                }
                .sheet(isPresented: $showingImport) {
                    ImportView(store: store)
                        .preferredColorScheme(settingsManager.settings.colorScheme.colorScheme)
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
                .fullScreenCover(isPresented: $showingTuner) {
                    TunerView()
                        .preferredColorScheme(settingsManager.settings.colorScheme.colorScheme)
                }
            }
            .tint(.orange)

            ToolPanelView(isPresented: $showingMenu) { item in
                handleMenuSelection(item)
            }
        }
        .id(settingsManager.settings.colorScheme)
    }

    // MARK: - Obsługa menu

    private func handleMenuSelection(_ item: ToolMenuItem) {
        switch item {
        case .tuner:    showingTuner    = true
        case .settings: showingSettings = true
        }
    }

    // MARK: - Helpers

    private var tagCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for tag in store.allTags {
            counts[tag] = store.songs(withTag: tag).count
        }
        return counts
    }

    // MARK: - Subviews

    private var songList: some View {
        List {
            ForEach(filteredSongs) { song in
                NavigationLink(value: song.id) {
                    SongRowView(song: song, colorScheme: effectiveScheme, lang: lang)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.cardBackground(for: effectiveScheme))
                        .padding(.vertical, 3)
                        .padding(.horizontal, 12)
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowSeparator(.hidden)
            }
            .onDelete { offsets in
                let songsToDelete = offsets.map { filteredSongs[$0] }
                songsToDelete.forEach { store.delete($0) }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 64))
                .foregroundStyle(.orange.opacity(0.6))

            Text(L10n.noSongs.localized(for: lang))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.primaryText(for: effectiveScheme))

            Text(L10n.noSongsTapToAdd.localized(for: lang))
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText(for: effectiveScheme))
        }
    }

    private var noResultsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.secondaryText(for: effectiveScheme).opacity(0.5))

            if searchText.isEmpty, let tag = selectedTag {
                Text(L10n.noSongsWithTag(tag, for: lang))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText(for: effectiveScheme))

                Button {
                    withAnimation { selectedTag = nil }
                } label: {
                    Text(L10n.showAll.localized(for: lang))
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } else {
                Text(L10n.noResults.localized(for: lang))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText(for: effectiveScheme))
            }
        }
    }
}

// MARK: - Gest swipe od lewej krawędzi (UIKit – nie blokuje List scrolla)

struct EdgeSwipeArea: UIViewRepresentable {
    let onSwipe: () -> Void

    func makeUIView(context: Context) -> EdgeSwipeView {
        let view = EdgeSwipeView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true

        let pan = UIScreenEdgePanGestureRecognizer(
            target:  context.coordinator,
            action: #selector(Coordinator.handleSwipe(_:))
        )
        pan.edges = .left
        view.addGestureRecognizer(pan)

        return view
    }

    func updateUIView(_ uiView: EdgeSwipeView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onSwipe: onSwipe) }

    final class Coordinator: NSObject {
        let onSwipe: () -> Void
        init(onSwipe: @escaping () -> Void) { self.onSwipe = onSwipe }

        @objc func handleSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
            if gesture.state == .recognized { onSwipe() }
        }
    }
}

final class EdgeSwipeView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        point.x < 25
    }
}

// MARK: - Pasek filtrów tagów

struct TagFilterBar: View {
    let tags:        [String]
    @Binding var selectedTag: String?
    let songCounts:  [String: Int]
    let colorScheme: ColorScheme
    let lang:        AppLanguage

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                TagChip(
                    label:       L10n.allTags.localized(for: lang),
                    count:       nil,
                    isSelected:  selectedTag == nil,
                    colorScheme: colorScheme
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTag = nil }
                }

                ForEach(tags, id: \.self) { tag in
                    TagChip(
                        label:       tag,
                        count:       songCounts[tag],
                        isSelected:  selectedTag == tag,
                        colorScheme: colorScheme
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTag = selectedTag == tag ? nil : tag
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Chip tagu

struct TagChip: View {
    let label:       String
    let count:       Int?
    let isSelected:  Bool
    let colorScheme: ColorScheme
    let action:      () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))

                if let count {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(isSelected
                                      ? Color.black.opacity(0.15)
                                      : AppTheme.secondaryText(for: colorScheme).opacity(0.2))
                        )
                }
            }
            .foregroundStyle(isSelected ? .black : AppTheme.primaryText(for: colorScheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(isSelected ? Color.orange : AppTheme.cardBackground(for: colorScheme)))
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : AppTheme.separator(for: colorScheme), lineWidth: 1)
            )
        }
    }
}

// MARK: - Wiersz piosenki

struct SongRowView: View {
    let song:        Song
    let colorScheme: ColorScheme
    let lang:        AppLanguage

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 56, height: 56)

                Text(String(song.title.prefix(1)).uppercased())
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(song.title.isEmpty ? L10n.untitled.localized(for: lang) : song.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    let lineCount = song.content.components(separatedBy: "\n").count

                    Text(L10n.linesAndSpeed(lineCount, Int(song.scrollSpeed), for: lang))
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))

                    if !song.tags.isEmpty {
                        Text("•")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))

                        ForEach(song.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.chordButtonBackground(for: colorScheme))
                                )
                        }

                        if song.tags.count > 2 {
                            Text("+\(song.tags.count - 2)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
    }
}

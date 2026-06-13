import SwiftUI

struct ContentView: View {
    @StateObject private var store = SongStore()
    @State private var showingNewSong = false
    @State private var showingImport = false
    @State private var showingSettings = false
    @State private var showingTuner = false
    @State private var showingMenu = false
    @State private var searchText = ""
    @State private var selectedTag: String? = nil
    @Environment(\.colorScheme) private var colorScheme

    var filteredSongs: [Song] {
        var result = store.songs
        
        // Filtruj po tagu
        if let tag = selectedTag {
            result = result.filter { $0.tags.contains(tag) }
        }
        
        // Filtruj po tekście wyszukiwania (przeszukuje WSZYSTKIE piosenki)
        if !searchText.isEmpty {
            result = store.songs.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }
        
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background(for: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filtry tagów
                    if !store.allTags.isEmpty && searchText.isEmpty {
                        TagFilterBar(
                            tags: store.allTags,
                            selectedTag: $selectedTag,
                            songCounts: tagCounts
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
            }
            .navigationTitle("Biblioteka")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Szukaj piosenki…")
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
            }
            .sheet(isPresented: $showingImport) {
                ImportView(store: store)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showingTuner) {
                TunerView()
            }
        }
        .tint(.orange)
        .overlay {
            ToolPanelView(isPresented: $showingMenu) { item in
                handleMenuSelection(item)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    let screenWidth = UIScreen.main.bounds.width
                    
                    if !showingMenu {
                        // Swipe w prawo z lewych 25% ekranu → otwórz menu
                        if value.startLocation.x < screenWidth * 0.25 && value.translation.width > 60 {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                showingMenu = true
                            }
                        }
                    } else {
                        // Swipe w lewo → zamknij menu
                        if value.translation.width < -60 {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                showingMenu = false
                            }
                        }
                    }
                }
        )
    }
    
    // MARK: - Obsługa wyboru z menu
    
    private func handleMenuSelection(_ item: ToolMenuItem) {
        switch item {
        case .tuner:
            showingTuner = true
        case .settings:
            showingSettings = true
        }
    }
    
    // MARK: - Pomocnicze
    
    private var tagCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for tag in store.allTags {
            counts[tag] = store.songs(withTag: tag).count
        }
        return counts
    }

    private var songList: some View {
        List {
            ForEach(filteredSongs) { song in
                NavigationLink(destination: SongDetailView(store: store, song: song)) {
                    SongRowView(song: song)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.cardBackground(for: colorScheme))
                        .padding(.vertical, 2)
                )
                .listRowSeparator(.hidden)
            }
            .onDelete { offsets in
                let songsToDelete = offsets.map { filteredSongs[$0] }
                for song in songsToDelete {
                    store.delete(song)
                }
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
            Text("Brak piosenek")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            Text("Dotknij + aby dodać pierwszą piosenkę")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
        }
    }
    
    private var noResultsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme).opacity(0.5))
            
            if searchText.isEmpty && selectedTag != nil {
                Text("Brak piosenek z tagiem: \(selectedTag!)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                
                Button {
                    withAnimation { selectedTag = nil }
                } label: {
                    Text("Pokaż wszystkie")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } else {
                Text("Brak wyników")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            }
        }
    }
}

// MARK: - Pasek filtrów tagów

struct TagFilterBar: View {
    let tags: [String]
    @Binding var selectedTag: String?
    let songCounts: [String: Int]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                TagChip(
                    label: "Wszystkie",
                    count: nil,
                    isSelected: selectedTag == nil
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTag = nil }
                }
                
                ForEach(tags, id: \.self) { tag in
                    TagChip(
                        label: tag,
                        count: songCounts[tag],
                        isSelected: selectedTag == tag
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

struct TagChip: View {
    let label: String
    let count: Int?
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                
                if let count = count {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.black.opacity(0.15) : AppTheme.secondaryText(for: colorScheme).opacity(0.2))
                        )
                }
            }
            .foregroundStyle(isSelected ? .black : AppTheme.primaryText(for: colorScheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.orange : AppTheme.cardBackground(for: colorScheme))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : AppTheme.separator(for: colorScheme), lineWidth: 1)
            )
        }
    }
}

// MARK: - Wiersz piosenki

struct SongRowView: View {
    let song: Song
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 48, height: 48)
                Text(String(song.title.prefix(1)).uppercased())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title.isEmpty ? "Bez tytułu" : song.title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    let lineCount = song.content.components(separatedBy: "\n").count
                    Text("\(lineCount) linii • \(Int(song.scrollSpeed)) px/s")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    
                    if !song.tags.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                        
                        ForEach(song.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.chordButtonBackground(for: colorScheme))
                                )
                        }
                        
                        if song.tags.count > 2 {
                            Text("+\(song.tags.count - 2)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }
}

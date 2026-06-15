import SwiftUI
import Foundation
import Combine

struct Song: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var content: String
    var scrollSpeed: Double
    var fontSize: Double
    var capo: Int?
    var tags: [String] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(title: String = "", content: String = "", scrollSpeed: Double = 40, fontSize: Double = 22, capo: Int? = nil, tags: [String] = []) {
        self.title = title
        self.content = content
        self.scrollSpeed = scrollSpeed
        self.fontSize = fontSize
        self.capo = capo
        self.tags = tags
    }
    
    var capoDisplayText: String {
        if let capo = capo, capo > 0 {
            return L10n.capoFret(capo)
        }
        return L10n.none.localized()
    }
}

class SongStore: ObservableObject {
    @Published var songs: [Song] = []

    private let saveKey = "saved_songs"

    init() {
        load()
        if songs.isEmpty {
            let example = Song(
                title: L10n.exampleSongTitle.localized(),
                content: L10n.exampleSongContent.localized(),
                scrollSpeed: 40,
                fontSize: 22,
                capo: nil,
                tags: [L10n.exampleTag.localized()]
            )
            songs.append(example)
            save()
        }
    }

    // MARK: - CRUD
    
    func add(_ song: Song) {
        songs.insert(song, at: 0)
        save()
    }

    func update(_ song: Song) {
        if let idx = songs.firstIndex(where: { $0.id == song.id }) {
            var updated = song
            updated.updatedAt = Date()
            songs[idx] = updated
            save()
        }
    }

    func delete(at offsets: IndexSet) {
        songs.remove(atOffsets: offsets)
        save()
    }

    func delete(_ song: Song) {
        songs.removeAll { $0.id == song.id }
        save()
    }
    
    // MARK: - Tagi
    
    /// Wszystkie unikalne tagi ze wszystkich piosenek, posortowane
    var allTags: [String] {
        let all = songs.flatMap { $0.tags }
        let unique = Array(Set(all))
        return unique.sorted()
    }
    
    /// Piosenki z danym tagiem
    func songs(withTag tag: String) -> [Song] {
        songs.filter { $0.tags.contains(tag) }
    }
    
    /// Zmień nazwę tagu we wszystkich piosenkach
    func renameTag(from oldName: String, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != oldName else { return }
        
        for i in songs.indices {
            if let tagIdx = songs[i].tags.firstIndex(of: oldName) {
                songs[i].tags[tagIdx] = trimmed
            }
        }
        save()
    }
    
    /// Usuń tag ze wszystkich piosenek
    func deleteTag(_ tag: String) {
        for i in songs.indices {
            songs[i].tags.removeAll { $0 == tag }
        }
        save()
    }

    // MARK: - Persistence
    
    private func save() {
        if let data = try? JSONEncoder().encode(songs) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Song].self, from: data) {
            songs = decoded
        }
    }
}

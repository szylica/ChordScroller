import Foundation

// MARK: - Model akordu

struct ChordDefinition {
    let name: String
    let frets: [Int]        // 6 strun: -1 = nie graj, 0 = otwarta, 1+ = próg
    let fingers: [Int]      // 6 strun: 0 = brak palca, 1-4 = palec
    let baseFret: Int       // od którego progu zaczynamy (1 = początek gryfu)
    let barres: [Int]       // progi z barré (np. [1] dla F)
    
    init(_ name: String, frets: [Int], fingers: [Int] = [0,0,0,0,0,0], baseFret: Int = 1, barres: [Int] = []) {
        self.name = name
        self.frets = frets
        self.fingers = fingers
        self.baseFret = baseFret
        self.barres = barres
    }
}

// MARK: - Baza akordów

struct ChordDatabase {
    
    static let shared = ChordDatabase()
    
    private let chords: [String: ChordDefinition]
    
    private init() {
        var db: [String: ChordDefinition] = [:]
        
        // ===== AKORDY DUROWE =====
        
        // C
        db["C"] = ChordDefinition("C",
            frets:   [-1, 3, 2, 0, 1, 0],
            fingers: [ 0, 3, 2, 0, 1, 0])
        
        // D
        db["D"] = ChordDefinition("D",
            frets:   [-1, -1, 0, 2, 3, 2],
            fingers: [ 0,  0, 0, 1, 3, 2])
        
        // E
        db["E"] = ChordDefinition("E",
            frets:   [0, 2, 2, 1, 0, 0],
            fingers: [0, 2, 3, 1, 0, 0])
        
        // F (barré)
        db["F"] = ChordDefinition("F",
            frets:   [1, 3, 3, 2, 1, 1],
            fingers: [1, 3, 4, 2, 1, 1],
            barres: [1])
        
        // G
        db["G"] = ChordDefinition("G",
            frets:   [3, 2, 0, 0, 0, 3],
            fingers: [2, 1, 0, 0, 0, 3])
        
        // A
        db["A"] = ChordDefinition("A",
            frets:   [-1, 0, 2, 2, 2, 0],
            fingers: [ 0, 0, 1, 2, 3, 0])
        
        // B / H (barré)
        db["B"] = ChordDefinition("B",
            frets:   [-1, 2, 4, 4, 4, 2],
            fingers: [ 0, 1, 2, 3, 4, 1],
            baseFret: 1,
            barres: [2])
        db["H"] = db["B"]!
        
        // ===== AKORDY MOLOWE =====
        
        // Am
        db["Am"] = ChordDefinition("Am",
            frets:   [-1, 0, 2, 2, 1, 0],
            fingers: [ 0, 0, 2, 3, 1, 0])
        db["am"] = db["Am"]!
        
        // Dm
        db["Dm"] = ChordDefinition("Dm",
            frets:   [-1, -1, 0, 2, 3, 1],
            fingers: [ 0,  0, 0, 2, 3, 1])
        db["dm"] = db["Dm"]!
        
        // Em
        db["Em"] = ChordDefinition("Em",
            frets:   [0, 2, 2, 0, 0, 0],
            fingers: [0, 2, 3, 0, 0, 0])
        db["em"] = db["Em"]!
        
        // Fm (barré)
        db["Fm"] = ChordDefinition("Fm",
            frets:   [1, 3, 3, 1, 1, 1],
            fingers: [1, 3, 4, 1, 1, 1],
            barres: [1])
        db["fm"] = db["Fm"]!
        
        // Gm (barré)
        db["Gm"] = ChordDefinition("Gm",
            frets:   [3, 5, 5, 3, 3, 3],
            fingers: [1, 3, 4, 1, 1, 1],
            baseFret: 3,
            barres: [3])
        db["gm"] = db["Gm"]!
        
        // Bm (barré)
        db["Bm"] = ChordDefinition("Bm",
            frets:   [-1, 2, 4, 4, 3, 2],
            fingers: [ 0, 1, 3, 4, 2, 1],
            baseFret: 1,
            barres: [2])
        db["Hm"] = db["Bm"]!
        db["bm"] = db["Bm"]!
        db["hm"] = db["Bm"]!
        
        // Cm (barré)
        db["Cm"] = ChordDefinition("Cm",
            frets:   [-1, 3, 5, 5, 4, 3],
            fingers: [ 0, 1, 3, 4, 2, 1],
            baseFret: 3,
            barres: [3])
        db["cm"] = db["Cm"]!
        
        // ===== AKORDY SEPTYMOWE (7) =====
        
        // A7
        db["A7"] = ChordDefinition("A7",
            frets:   [-1, 0, 2, 0, 2, 0],
            fingers: [ 0, 0, 2, 0, 3, 0])
        
        // B7
        db["B7"] = ChordDefinition("B7",
            frets:   [-1, 2, 1, 2, 0, 2],
            fingers: [ 0, 2, 1, 3, 0, 4])
        db["H7"] = db["B7"]!
        
        // C7
        db["C7"] = ChordDefinition("C7",
            frets:   [-1, 3, 2, 3, 1, 0],
            fingers: [ 0, 3, 2, 4, 1, 0])
        
        // D7
        db["D7"] = ChordDefinition("D7",
            frets:   [-1, -1, 0, 2, 1, 2],
            fingers: [ 0,  0, 0, 2, 1, 3])
        
        // E7
        db["E7"] = ChordDefinition("E7",
            frets:   [0, 2, 0, 1, 0, 0],
            fingers: [0, 2, 0, 1, 0, 0])
        
        // G7
        db["G7"] = ChordDefinition("G7",
            frets:   [3, 2, 0, 0, 0, 1],
            fingers: [3, 2, 0, 0, 0, 1])
        
        // Am7
        db["Am7"] = ChordDefinition("Am7",
            frets:   [-1, 0, 2, 0, 1, 0],
            fingers: [ 0, 0, 2, 0, 1, 0])
        
        // Em7
        db["Em7"] = ChordDefinition("Em7",
            frets:   [0, 2, 0, 0, 0, 0],
            fingers: [0, 2, 0, 0, 0, 0])
        
        // Dm7
        db["Dm7"] = ChordDefinition("Dm7",
            frets:   [-1, -1, 0, 2, 1, 1],
            fingers: [ 0,  0, 0, 2, 1, 1])
        
        // ===== AKORDY MOLOWE SEPTYMOWE (m7) =====
        
        // Bm7
        db["Bm7"] = ChordDefinition("Bm7",
            frets:   [-1, 2, 0, 2, 3, 2],
            fingers: [ 0, 1, 0, 2, 4, 3])
        db["Hm7"] = db["Bm7"]!
        
        // ===== AKORDY SUS =====
        
        // Dsus2
        db["Dsus2"] = ChordDefinition("Dsus2",
            frets:   [-1, -1, 0, 2, 3, 0],
            fingers: [ 0,  0, 0, 1, 2, 0])
        
        // Dsus4
        db["Dsus4"] = ChordDefinition("Dsus4",
            frets:   [-1, -1, 0, 2, 3, 3],
            fingers: [ 0,  0, 0, 1, 2, 3])
        
        // Asus2
        db["Asus2"] = ChordDefinition("Asus2",
            frets:   [-1, 0, 2, 2, 0, 0],
            fingers: [ 0, 0, 1, 2, 0, 0])
        
        // Asus4
        db["Asus4"] = ChordDefinition("Asus4",
            frets:   [-1, 0, 2, 2, 3, 0],
            fingers: [ 0, 0, 1, 2, 3, 0])
        
        // Esus4
        db["Esus4"] = ChordDefinition("Esus4",
            frets:   [0, 2, 2, 2, 0, 0],
            fingers: [0, 2, 3, 4, 0, 0])
        
        // ===== AKORDY ADD =====
        
        // Cadd9
        db["Cadd9"] = ChordDefinition("Cadd9",
            frets:   [-1, 3, 2, 0, 3, 0],
            fingers: [ 0, 2, 1, 0, 3, 0])
        
        // Gadd9
        db["Gadd9"] = ChordDefinition("Gadd9",
            frets:   [3, 2, 0, 2, 0, 3],
            fingers: [2, 1, 0, 3, 0, 4])
        
        // ===== AKORDY Z # i b =====
        
        // F#m (barré)
        db["F#m"] = ChordDefinition("F#m",
            frets:   [2, 4, 4, 2, 2, 2],
            fingers: [1, 3, 4, 1, 1, 1],
            baseFret: 2,
            barres: [2])
        db["Fis"] = db["F#m"]!
        db["Fism"] = db["F#m"]!
        
        // C#m (barré)
        db["C#m"] = ChordDefinition("C#m",
            frets:   [-1, 4, 6, 6, 5, 4],
            fingers: [ 0, 1, 3, 4, 2, 1],
            baseFret: 4,
            barres: [4])
        db["Cism"] = db["C#m"]!
        
        // G#m (barré)
        db["G#m"] = ChordDefinition("G#m",
            frets:   [4, 6, 6, 4, 4, 4],
            fingers: [1, 3, 4, 1, 1, 1],
            baseFret: 4,
            barres: [4])
        db["Gism"] = db["G#m"]!
        
        // Bb (barré)
        db["Bb"] = ChordDefinition("Bb",
            frets:   [-1, 1, 3, 3, 3, 1],
            fingers: [ 0, 1, 2, 3, 4, 1],
            barres: [1])
        db["B♭"] = db["Bb"]!
        
        // Eb (barré)
        db["Eb"] = ChordDefinition("Eb",
            frets:   [-1, 6, 8, 8, 8, 6],
            fingers: [ 0, 1, 2, 3, 4, 1],
            baseFret: 6,
            barres: [6])
        db["E♭"] = db["Eb"]!
        
        // F# (barré)
        db["F#"] = ChordDefinition("F#",
            frets:   [2, 4, 4, 3, 2, 2],
            fingers: [1, 3, 4, 2, 1, 1],
            baseFret: 2,
            barres: [2])
        db["Fis"] = db["F#"]!
        
        // C# (barré)
        db["C#"] = ChordDefinition("C#",
            frets:   [-1, 4, 6, 6, 6, 4],
            fingers: [ 0, 1, 2, 3, 4, 1],
            baseFret: 4,
            barres: [4])
        db["Cis"] = db["C#"]!
        
        // D# (barré) - same as Eb
        db["D#"] = db["Eb"]!
        db["Dis"] = db["Eb"]!
        
        // G# (barré)
        db["G#"] = ChordDefinition("G#",
            frets:   [4, 6, 6, 5, 4, 4],
            fingers: [1, 3, 4, 2, 1, 1],
            baseFret: 4,
            barres: [4])
        db["Gis"] = db["G#"]!
        
        // A# (barré) - same as Bb
        db["A#"] = db["Bb"]!
        db["Ais"] = db["Bb"]!
        
        self.chords = db
    }
    
    /// Znajdź akord po nazwie
    func find(_ name: String) -> ChordDefinition? {
        // Próbuj dokładne dopasowanie
        if let chord = chords[name] {
            return chord
        }
        
        // Próbuj warianty nazwy
        let normalized = name
            .replacingOccurrences(of: "maj", with: "")
            .replacingOccurrences(of: "M", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        if let chord = chords[normalized] {
            return chord
        }
        
        return nil
    }
    
    /// Wyciągnij wszystkie unikalne akordy z tekstu piosenki
    static func extractChords(from content: String) -> [String] {
        let pattern = #"\[([^\]]+)\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        
        let nsContent = content as NSString
        let matches = regex.matches(in: content, range: NSRange(location: 0, length: nsContent.length))
        
        var seen = Set<String>()
        var result: [String] = []
        
        for match in matches {
            let chordRange = match.range(at: 1)
            let chord = nsContent.substring(with: chordRange)
            
            if !seen.contains(chord) {
                seen.insert(chord)
                result.append(chord)
            }
        }
        
        return result
    }
}

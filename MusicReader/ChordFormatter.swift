import Foundation

// MARK: - Segment: słowo z opcjonalnym akordem

struct ChordSegment: Identifiable {
    let id = UUID()
    let chord: String?
    let text: String // słowo lub chunk słowa ze spacjami
    
    var hasChord: Bool {
        chord != nil && !chord!.isEmpty
    }
}

// MARK: - Sparsowana linia

struct ParsedLine: Identifiable {
    let id = UUID()
    let segments: [ChordSegment]
    let isEmpty: Bool
    let hasChords: Bool
    let rawText: String
}

// MARK: - Parser

struct ChordFormatter {
    
    /// Parsuje całą treść na linie
    static func parseContent(_ content: String) -> [ParsedLine] {
        content.components(separatedBy: "\n").map { parseLine($0) }
    }
    
    /// Parsuje pojedynczą linię na segmenty
    static func parseLine(_ line: String) -> ParsedLine {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return ParsedLine(segments: [], isEmpty: true, hasChords: false, rawText: "")
        }
        
        guard containsChords(line) else {
            return ParsedLine(
                segments: [ChordSegment(chord: nil, text: line)],
                isEmpty: false,
                hasChords: false,
                rawText: line
            )
        }
        
        let segments = buildSegments(from: line)
        let rawText = segments.map { $0.text }.joined()
        return ParsedLine(segments: segments, isEmpty: false, hasChords: true, rawText: rawText)
    }
    
    // MARK: - Algorytm budowania segmentów
    
    private static func buildSegments(from line: String) -> [ChordSegment] {
        // Faza 1: Skanuj linię → wyciągnij pary (akord, tekst za nim)
        
        var rawPairs: [(chord: String?, text: String)] = []
        var pendingChord: String? = nil
        var currentText = ""
        var inChord = false
        var chordBuffer = ""
        
        for char in line {
            if char == "[" {
                if !currentText.isEmpty || pendingChord != nil {
                    rawPairs.append((pendingChord, currentText))
                    pendingChord = nil
                    currentText = ""
                }
                inChord = true
                chordBuffer = ""
            } else if char == "]" && inChord {
                inChord = false
                pendingChord = chordBuffer.trimmingCharacters(in: .whitespaces)
            } else if inChord {
                chordBuffer.append(char)
            } else {
                currentText.append(char)
            }
        }
        // Resztki
        if !currentText.isEmpty || pendingChord != nil {
            rawPairs.append((pendingChord, currentText))
        }
        
        // Faza 2: Rozbij długi tekst na słowa (dla poprawnego zawijania),
        // ale akord przypisuj TYLKO do pierwszego słowa.
        
        var segments: [ChordSegment] = []
        
        for pair in rawPairs {
            let words = splitKeepingSpaces(pair.text)
            
            if words.isEmpty {
                // Akord bez tekstu (np. [G] na końcu linii lub [G][Cadd9])
                if let chord = pair.chord, !chord.isEmpty {
                    segments.append(ChordSegment(chord: chord, text: ""))
                }
            } else {
                for (idx, word) in words.enumerated() {
                    let chord = (idx == 0) ? pair.chord : nil
                    segments.append(ChordSegment(chord: chord, text: word))
                }
            }
        }
        
        return segments
    }
    
    // MARK: - Dzielenie tekstu na słowa z zachowaniem spacji
    
    /// Dzieli tekst na słowa, gdzie każde słowo zachowuje swoje trailing spacje.
    /// "o mnie w " → ["o ", "mnie ", "w "]
    /// "mieście:" → ["mieście:"]
    /// "" → []
    private static func splitKeepingSpaces(_ text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        
        var words: [String] = []
        var current = ""
        var wasSpace = false
        
        for char in text {
            if char.isWhitespace {
                current.append(char)
                wasSpace = true
            } else {
                if wasSpace && !current.isEmpty {
                    // Nowe słowo się zaczyna – zapisz poprzednie (ze spacjami na końcu)
                    words.append(current)
                    current = ""
                }
                current.append(char)
                wasSpace = false
            }
        }
        
        if !current.isEmpty {
            words.append(current)
        }
        
        return words
    }
    
    // MARK: - Pomocnicze
    
    private static func containsChords(_ text: String) -> Bool {
        text.range(of: #"\[[^\]]+\]"#, options: .regularExpression) != nil
    }
}

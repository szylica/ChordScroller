import Foundation

// MARK: - Segment: słowo z opcjonalnym akordem

struct ChordSegment: Identifiable {
    let id = UUID()
    let chord: String?
    let text: String       // słowo Z trailing spacją jeśli nie jest ostatnie
    
    var hasChord: Bool { chord != nil && !chord!.isEmpty }
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
        
        guard containsChords(trimmed) else {
            return ParsedLine(
                segments: [ChordSegment(chord: nil, text: trimmed)],
                isEmpty: false, hasChords: false, rawText: trimmed
            )
        }
        
        let segments = buildSegments(from: line)
        let rawText = segments.map { $0.text }.joined()
        
        return ParsedLine(segments: segments, isEmpty: false, hasChords: true, rawText: rawText)
    }
    
    // MARK: - Parser wewnętrzny
    
    private static func buildSegments(from line: String) -> [ChordSegment] {
        let pattern = #"\[([^\]]+)\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [ChordSegment(chord: nil, text: line)]
        }
        
        let nsLine = line as NSString
        let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
        
        guard !matches.isEmpty else {
            return [ChordSegment(chord: nil, text: line)]
        }
        
        // 1. Wyciągnij tekst bez akordów i pozycje akordów
        var cleanText = ""
        var chordPositions: [(chord: String, position: Int)] = []
        var lastEnd = 0
        
        for match in matches {
            // Tekst przed akordem
            let beforeRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
            let before = nsLine.substring(with: beforeRange)
            
            let pos = cleanText.count + before.count
            let chord = nsLine.substring(with: match.range(at: 1))
            
            chordPositions.append((chord, pos))
            cleanText += before
            lastEnd = match.range.location + match.range.length
        }
        
        // Tekst po ostatnim akordzie
        if lastEnd < nsLine.length {
            cleanText += nsLine.substring(from: lastEnd)
        }
        
        // 2. Podziel tekst na słowa (zachowując pozycje)
        //    Każde słowo = zakres znaków w cleanText
        var wordRanges: [(start: Int, end: Int)] = []
        var wordStart: Int? = nil
        
        for (i, char) in cleanText.enumerated() {
            if char == " " {
                if let ws = wordStart {
                    wordRanges.append((ws, i))
                    wordStart = nil
                }
            } else {
                if wordStart == nil { wordStart = i }
            }
        }
        if let ws = wordStart {
            wordRanges.append((ws, cleanText.count))
        }
        
        // 3. Przypisz akordy do słów
        guard !wordRanges.isEmpty else {
            // Tylko akordy, brak tekstu
            return chordPositions.map { ChordSegment(chord: $0.chord, text: "") }
        }
        
        // Dla każdego słowa znajdź akord który jest przy nim (przed lub na początku słowa)
        var segments: [ChordSegment] = []
        var usedChords = Set<Int>()
        
        for (wordIdx, wordRange) in wordRanges.enumerated() {
            let wordText = substring(cleanText, from: wordRange.start, to: wordRange.end)
            
            // Czy to ostatnie słowo?
            let isLast = wordIdx == wordRanges.count - 1
            // Dodaj spację po słowie (chyba że ostatnie)
            let displayText = isLast ? wordText : wordText + " "
            
            // Znajdź akord dla tego słowa
            var assignedChord: String? = nil
            
            for (chordIdx, cp) in chordPositions.enumerated() {
                if usedChords.contains(chordIdx) { continue }
                
                // Akord jest przypisany do słowa jeśli jego pozycja jest:
                // - na początku lub w środku tego słowa
                // - lub między końcem poprzedniego słowa a początkiem tego
                let prevEnd = wordIdx > 0 ? wordRanges[wordIdx - 1].end : 0
                
                if cp.position >= prevEnd && cp.position <= wordRange.end {
                    if assignedChord == nil {
                        assignedChord = cp.chord
                        usedChords.insert(chordIdx)
                    } else {
                        // Wiele akordów na jedno słowo - dodaj poprzedni segment i zacznij nowy
                        // (rzadki przypadek)
                        assignedChord = assignedChord! + " " + cp.chord
                        usedChords.insert(chordIdx)
                    }
                }
            }
            
            segments.append(ChordSegment(chord: assignedChord, text: displayText))
        }
        
        // Akordy na końcu bez tekstu
        for (chordIdx, cp) in chordPositions.enumerated() {
            if !usedChords.contains(chordIdx) {
                segments.append(ChordSegment(chord: cp.chord, text: " "))
            }
        }
        
        return segments
    }
    
    private static func substring(_ str: String, from: Int, to: Int) -> String {
        let start = str.index(str.startIndex, offsetBy: from)
        let end = str.index(str.startIndex, offsetBy: min(to, str.count))
        return String(str[start..<end])
    }
    
    static func containsChords(_ text: String) -> Bool {
        text.range(of: #"\[[^\]]+\]"#, options: .regularExpression) != nil
    }
}

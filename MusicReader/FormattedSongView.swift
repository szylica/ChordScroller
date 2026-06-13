import SwiftUI

// MARK: - Główny widok piosenki

struct FormattedSongView: View {
    let content: String
    let fontSize: Double
    let onChordTap: ((String) -> Void)?
    
    init(content: String, fontSize: Double, onChordTap: ((String) -> Void)? = nil) {
        self.content = content
        self.fontSize = fontSize
        self.onChordTap = onChordTap
    }
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let lines = ChordFormatter.parseContent(content)
        
        VStack(alignment: .leading, spacing: 14) {
            ForEach(lines) { line in
                if line.isEmpty {
                    Color.clear.frame(height: fontSize * 0.5)
                } else if line.hasChords {
                    WrappingChordLineView(
                        segments: line.segments,
                        fontSize: fontSize,
                        onChordTap: onChordTap
                    )
                } else {
                    Text(line.rawText)
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Linia z akordami (FlowLayout)

struct WrappingChordLineView: View {
    let segments: [ChordSegment]
    let fontSize: Double
    let onChordTap: ((String) -> Void)?
    
    var body: some View {
        FlowLayout(spacing: 0, lineSpacing: fontSize * 0.5) {
            ForEach(segments) { segment in
                WordSegmentView(
                    segment: segment,
                    fontSize: fontSize,
                    onChordTap: onChordTap
                )
            }
        }
    }
}

// MARK: - Segment: akord nad słowem

struct WordSegmentView: View {
    let segment: ChordSegment
    let fontSize: Double
    let onChordTap: ((String) -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    
    private var chordSize: Double { fontSize * 0.85 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Linia akordu
            if let chord = segment.chord, !chord.isEmpty {
                if let tap = onChordTap {
                    Button { tap(chord) } label: { chordLabel(chord) }
                } else {
                    chordLabel(chord)
                }
            } else {
                // Pusty placeholder (ta sama wysokość co akord)
                Text(" ")
                    .font(.system(size: chordSize, weight: .bold, design: .monospaced))
                    .foregroundStyle(.clear)
            }
            
            // Linia tekstu
            Text(segment.text)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
        }
        .fixedSize() // KLUCZOWE: segment raportuje swój naturalny rozmiar
    }
    
    private func chordLabel(_ chord: String) -> some View {
        Text(chord)
            .font(.system(size: chordSize, weight: .bold, design: .monospaced))
            .foregroundStyle(.orange)
    }
}

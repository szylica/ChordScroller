import SwiftUI

struct ChordDiagramView: View {
    let chord: ChordDefinition  
    let size: CGFloat
    @Environment(\.colorScheme) private var colorScheme
    
    init(chord: ChordDefinition, size: CGFloat = 120) {
        self.chord = chord
        self.size = size
    }
    
    // Wymiary
    private var stringSpacing: CGFloat { size / 7 }
    private var fretSpacing: CGFloat { size / 5 }
    private var fretCount: Int { 4 }
    private var dotRadius: CGFloat { stringSpacing * 0.35 }
    private var gridWidth: CGFloat { stringSpacing * 5 }
    private var gridHeight: CGFloat { fretSpacing * CGFloat(fretCount) }
    
    var body: some View {
        VStack(spacing: 8) {
            // Nazwa akordu
            Text(chord.name)
                .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                .foregroundStyle(.orange)
            
            // Diagram
            ZStack(alignment: .topLeading) {
                // Siatka gryfu
                fretBoard
                
                // Nakładka: barré, palce, X/O
                fingerPositions
            }
            .frame(width: gridWidth + stringSpacing, height: gridHeight + fretSpacing * 1.2)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.inputBackground(for: colorScheme))
        )
    }
    
    // MARK: - Siatka gryfu
    
    private var fretBoard: some View {
        ZStack(alignment: .topLeading) {
            // Progi (poziome linie)
            ForEach(0...fretCount, id: \.self) { fret in
                Rectangle()
                    .fill(fret == 0 ? AppTheme.primaryText(for: colorScheme) : Color.gray.opacity(0.5))
                    .frame(width: gridWidth, height: fret == 0 ? 4 : 1)
                    .offset(x: stringSpacing * 0.5, y: fretSpacing * 0.8 + CGFloat(fret) * fretSpacing)
            }
            
            // Struny (pionowe linie)
            ForEach(0..<6, id: \.self) { string in
                Rectangle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 1, height: gridHeight)
                    .offset(x: stringSpacing * 0.5 + CGFloat(string) * stringSpacing, y: fretSpacing * 0.8)
            }
            
            // Numer progu bazowego (jeśli > 1)
            if chord.baseFret > 1 {
                Text("\(chord.baseFret)")
                    .font(.system(size: size * 0.1, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    .offset(x: -stringSpacing * 0.3, y: fretSpacing * 1.1)
            }
        }
    }
    
    // MARK: - Pozycje palców
    
    private var fingerPositions: some View {
        ZStack(alignment: .topLeading) {
            // Barré
            ForEach(chord.barres, id: \.self) { barreFret in
                let relativeFret = barreFret - chord.baseFret + 1
                
                // Znajdź zakres barré
                let barreStrings = findBarreStrings(fret: barreFret)
                if barreStrings.count >= 2 {
                    let firstString = barreStrings.first!
                    let lastString = barreStrings.last!
                    
                    Capsule()
                        .fill(Color.orange.opacity(0.8))
                        .frame(
                            width: CGFloat(lastString - firstString) * stringSpacing + dotRadius * 2,
                            height: dotRadius * 1.8
                        )
                        .offset(
                            x: stringSpacing * 0.5 + CGFloat(firstString) * stringSpacing - dotRadius,
                            y: fretSpacing * 0.8 + (CGFloat(relativeFret) - 0.5) * fretSpacing - dotRadius * 0.9
                        )
                }
            }
            
            // Poszczególne struny
            ForEach(0..<6, id: \.self) { string in
                let fret = chord.frets[string]
                let x = stringSpacing * 0.5 + CGFloat(string) * stringSpacing
                
                if fret == -1 {
                    // X - nie graj tej struny
                    Text("×")
                        .font(.system(size: size * 0.12, weight: .bold))
                        .foregroundStyle(.red.opacity(0.8))
                        .offset(x: x - size * 0.04, y: fretSpacing * 0.3)
                } else if fret == 0 {
                    // O - otwarta struna
                    Circle()
                        .stroke(AppTheme.primaryText(for: colorScheme).opacity(0.8), lineWidth: 2)
                        .frame(width: dotRadius * 1.6, height: dotRadius * 1.6)
                        .offset(x: x - dotRadius * 0.8, y: fretSpacing * 0.35)
                } else {
                    // Palec na progu
                    let relativeFret = fret - chord.baseFret + 1
                    
                    // Nie rysuj jeśli to część barré
                    if !isPartOfBarre(string: string, fret: fret) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: dotRadius * 2, height: dotRadius * 2)
                            .offset(
                                x: x - dotRadius,
                                y: fretSpacing * 0.8 + (CGFloat(relativeFret) - 0.5) * fretSpacing - dotRadius
                            )
                        
                        // Numer palca (opcjonalnie)
                        if chord.fingers[string] > 0 {
                            Text("\(chord.fingers[string])")
                                .font(.system(size: dotRadius * 1.2, weight: .bold))
                                .foregroundStyle(.black)
                                .offset(
                                    x: x - dotRadius * 0.35,
                                    y: fretSpacing * 0.8 + (CGFloat(relativeFret) - 0.5) * fretSpacing - dotRadius * 0.65
                                )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func findBarreStrings(fret: Int) -> [Int] {
        var strings: [Int] = []
        for (index, f) in chord.frets.enumerated() {
            if f == fret {
                strings.append(index)
            }
        }
        return strings.sorted()
    }
    
    private func isPartOfBarre(string: Int, fret: Int) -> Bool {
        guard chord.barres.contains(fret) else { return false }
        
        let barreStrings = findBarreStrings(fret: fret)
        guard barreStrings.count >= 2,
              let first = barreStrings.first,
              let last = barreStrings.last else { return false }
        
        return string > first && string < last && chord.frets[string] == fret
    }
}

// MARK: - Podgląd nieznanego akordu

struct UnknownChordView: View {
    let name: String
    let size: CGFloat
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Text(name)
                .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                .foregroundStyle(.orange)
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.separator(for: colorScheme), lineWidth: 1)
                    .frame(width: size * 0.7, height: size * 0.6)
                
                VStack(spacing: 4) {
                    Image(systemName: "questionmark")
                        .font(.system(size: size * 0.2))
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    Text("Brak diagramu")
                        .font(.system(size: size * 0.08))
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.inputBackground(for: colorScheme))
        )
    }
}

// MARK: - Pomocniczy widok dla pojedynczego akordu

//struct ChordBadgeView: View {
//    let chordName: String
//    let isSelected: Bool
//    let action: () -> Void
//    @Environment(\.colorScheme) private var colorScheme
//    
//    var body: some View {
//        Button(action: action) {
//            Text(chordName)
//                .font(.system(size: 14, weight: .bold, design: .monospaced))
//                .foregroundStyle(isSelected ? .black : .orange)
//                .padding(.horizontal, 12)
//                .padding(.vertical, 8)
//                .background(
//                    RoundedRectangle(cornerRadius: 8)
//                        .fill(isSelected ? Color.orange : AppTheme.chordButtonBackground(for: colorScheme))
//                )
//                .overlay(
//                    RoundedRectangle(cornerRadius: 8)
//                        .stroke(Color.orange.opacity(0.5), lineWidth: 1)
//                )
//        }
//    }
//}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        if let am = ChordDatabase.shared.find("Am") {
            ChordDiagramView(chord: am, size: 140)
        }
        if let f = ChordDatabase.shared.find("F") {
            ChordDiagramView(chord: f, size: 140)
        }
        if let g = ChordDatabase.shared.find("G") {
            ChordDiagramView(chord: g, size: 140)
        }
    }
    .padding()
    .background(Color.black)
}

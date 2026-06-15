import SwiftUI

// MARK: - Wspólny diagram akordu (używany w panelu i popupie)

struct ChordDiagramCard: View {
    let chord: ChordDefinition
    let diagramSize: CGFloat
    @Environment(\.colorScheme) private var colorScheme
    
    private var stringSpacing: CGFloat { diagramSize / 7 }
    private var fretSpacing: CGFloat { diagramSize / 5 }
    private var dotRadius: CGFloat { stringSpacing * 0.35 }
    private var gridWidth: CGFloat { stringSpacing * 5 }
    private var gridHeight: CGFloat { fretSpacing * 4 }
    
    var body: some View {
        VStack(spacing: 0) {
            // X/O nad gryfem
            HStack(spacing: 0) {
                ForEach(0..<6, id: \.self) { string in
                    let fret = chord.frets[string]
                    Group {
                        if fret == -1 {
                            Text("×")
                                .font(.system(size: diagramSize * 0.08, weight: .bold))
                                .foregroundStyle(.red.opacity(0.7))
                        } else if fret == 0 {
                            Circle()
                                .stroke(AppTheme.primaryText(for: colorScheme).opacity(0.7), lineWidth: 2)
                                .frame(width: diagramSize * 0.065, height: diagramSize * 0.065)
                        } else {
                            Color.clear.frame(width: diagramSize * 0.065, height: diagramSize * 0.065)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: diagramSize * 0.1)
                }
            }
            .frame(width: gridWidth)
            .padding(.bottom, 4)
            
            // Gryf
            ZStack(alignment: .topLeading) {
                // Progi
                ForEach(0...4, id: \.self) { fret in
                    Rectangle()
                        .fill(fret == 0 ? AppTheme.primaryText(for: colorScheme) : Color.gray.opacity(0.4))
                        .frame(width: gridWidth, height: fret == 0 ? 4 : 1)
                        .offset(y: CGFloat(fret) * fretSpacing)
                }
                
                // Struny
                ForEach(0..<6, id: \.self) { string in
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 1, height: gridHeight)
                        .offset(x: CGFloat(string) * stringSpacing)
                }
                
                // Numer progu bazowego
                if chord.baseFret > 1 {
                    Text("\(chord.baseFret)")
                        .font(.system(size: diagramSize * 0.065, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                        .offset(x: -stringSpacing * 0.9, y: fretSpacing * 0.3)
                }
                
                // Barré
                ForEach(chord.barres, id: \.self) { barreFret in
                    let rel = barreFret - chord.baseFret + 1
                    let barreStrings = (0..<6).filter { chord.frets[$0] == barreFret }.sorted()
                    if barreStrings.count >= 2, let first = barreStrings.first, let last = barreStrings.last {
                        Capsule()
                            .fill(Color.orange.opacity(0.85))
                            .frame(
                                width: CGFloat(last - first) * stringSpacing + dotRadius * 2,
                                height: dotRadius * 2
                            )
                            .offset(
                                x: CGFloat(first) * stringSpacing - dotRadius,
                                y: (CGFloat(rel) - 0.5) * fretSpacing - dotRadius
                            )
                    }
                }
                
                // Palce
                ForEach(0..<6, id: \.self) { string in
                    let fret = chord.frets[string]
                    if fret > 0 {
                        let rel = fret - chord.baseFret + 1
                        let isInBarre = chord.barres.contains(fret) && {
                            let bs = (0..<6).filter { chord.frets[$0] == fret }.sorted()
                            return bs.count >= 2 && string > (bs.first ?? 0) && string < (bs.last ?? 0)
                        }()
                        
                        if !isInBarre {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: dotRadius * 2.2, height: dotRadius * 2.2)
                                .overlay(
                                    Group {
                                        if chord.fingers[string] > 0 {
                                            Text("\(chord.fingers[string])")
                                                .font(.system(size: dotRadius * 1.3, weight: .bold))
                                                .foregroundStyle(.black)
                                        }
                                    }
                                )
                                .offset(
                                    x: CGFloat(string) * stringSpacing - dotRadius * 1.1,
                                    y: (CGFloat(rel) - 0.5) * fretSpacing - dotRadius * 1.1
                                )
                        }
                    }
                }
            }
            .frame(width: gridWidth, height: gridHeight)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Panel akordów w szczegółach piosenki

struct ChordsPanelView: View {
    let chords: [String]
    @State private var selectedChord: String?
    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Nagłówek
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                    if !isExpanded { selectedChord = nil }
                }
            } label: {
                HStack {
                    Image(systemName: "guitars")
                        .foregroundStyle(.orange)
                    
                    Text(L10n.chordsInSong.localized())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    
                    Text("(\(chords.count))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                }
                .padding(16)
            }
            
            if isExpanded {
                // Separator
                Rectangle()
                    .fill(AppTheme.separator(for: colorScheme))
                    .frame(height: 1)
                    .padding(.horizontal, 16)
                
                // Lista akordów
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(chords, id: \.self) { chord in
                            ChordBadgeView(
                                chordName: chord,
                                isSelected: selectedChord == chord
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedChord = selectedChord == chord ? nil : chord
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                // Diagram wybranego akordu
                if let selected = selectedChord {
                    Rectangle()
                        .fill(AppTheme.separator(for: colorScheme))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                    
                    if let definition = ChordDatabase.shared.find(selected) {
                        VStack(spacing: 0) {
                            // Nazwa akordu
                            Text(selected)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.orange)
                                .padding(.top, 16)
                            
                            // Diagram
                            ChordDiagramCard(chord: definition, diagramSize: 170)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                            
                            // Separator
                            Rectangle()
                                .fill(AppTheme.separator(for: colorScheme))
                                .frame(height: 1)
                                .padding(.horizontal, 16)
                            
                            // Strojenie strun
                            HStack(spacing: 0) {
                                ForEach(0..<6, id: \.self) { string in
                                    let fret = definition.frets[string]
                                    Text(fret == -1 ? "×" : "\(fret)")
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundStyle(fret == -1 ? .red.opacity(0.7) : AppTheme.secondaryText(for: colorScheme))
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 10)
                            
                            // Nazwy strun
                            HStack(spacing: 0) {
                                ForEach(["E", "A", "D", "G", "B", "e"], id: \.self) { name in
                                    Text(name)
                                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme).opacity(0.6))
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 12)
                        }
                    } else {
                        // Nieznany akord
                        VStack(spacing: 10) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 32))
                                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                            Text(L10n.noDiagramFor(selected))
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                    
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
    }
}

// MARK: - Popup z akordem (do użycia przy tapnięciu w tekst)

struct ChordPopupView: View {
    let chordName: String
    let onDismiss: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private let diagramSize: CGFloat = 200
    
    private var stringSpacing: CGFloat { diagramSize / 7 }
    private var fretSpacing: CGFloat { diagramSize / 5 }
    private var dotRadius: CGFloat { stringSpacing * 0.35 }
    
    var body: some View {
        ZStack {
            // Tło przyciemniające
            Color.black.opacity(colorScheme == .dark ? 0.7 : 0.4)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            // Karta
            VStack(spacing: 0) {
                // Nagłówek
                HStack {
                    Text(chordName)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(AppTheme.inputBackground(for: colorScheme))
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                Rectangle()
                    .fill(AppTheme.separator(for: colorScheme))
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                
                // Diagram
                if let definition = ChordDatabase.shared.find(chordName) {
                    ChordDiagramCard(chord: definition, diagramSize: diagramSize)
                        .padding(.vertical, 24)
                        .padding(.horizontal, 16)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                        Text(L10n.noDiagramFor(chordName))
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    }
                    .padding(.vertical, 32)
                }
                
                Rectangle()
                    .fill(AppTheme.separator(for: colorScheme))
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                
                // Strojenie strun
                if let definition = ChordDatabase.shared.find(chordName) {
                    HStack(spacing: 0) {
                        ForEach(0..<6, id: \.self) { string in
                            let fret = definition.frets[string]
                            Text(fret == -1 ? "×" : "\(fret)")
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(fret == -1 ? .red.opacity(0.7) : AppTheme.secondaryText(for: colorScheme))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    
                    HStack(spacing: 0) {
                        ForEach(["E", "A", "D", "G", "B", "e"], id: \.self) { name in
                            Text(name)
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundStyle(AppTheme.secondaryText(for: colorScheme).opacity(0.6))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.cardBackground(for: colorScheme))
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            )
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Badge akordu

struct ChordBadgeView: View {
    let chordName: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text(chordName)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(isSelected ? .black : .orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.orange : AppTheme.chordButtonBackground(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                )
        }
    }
}

#Preview {
    ChordsPanelView(chords: ["Am", "C", "G", "F", "Dm", "E7"])
        .padding()
        .background(Color.black)
}

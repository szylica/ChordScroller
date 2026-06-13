import SwiftUI

// MARK: - Pełnoekranowy widok stroika

struct TunerView: View {
    @StateObject private var engine = TunerEngine()
    @State private var lockedString: GuitarString? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    /// Nuta do wyświetlenia – albo z silnika, albo zablokowana struna
    private var displayNote: DetectedNote? {
        if let locked = lockedString, engine.currentFrequency > 0 {
            // Tryb zablokowany – oblicz odchylenie od wybranej struny
            return calculateNoteForLockedString(locked, frequency: engine.currentFrequency)
        }
        return engine.currentNote
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    if engine.isActive {
                        if let note = displayNote {
                            activeReadingView(note: note)
                                .opacity(engine.hasLiveSignal ? 1.0 : 0.5)
                                .animation(.easeInOut(duration: 0.3), value: engine.hasLiveSignal)
                        } else {
                            waitingForSignalView
                        }
                    } else {
                        noMicrophoneView
                    }
                    
                    Spacer()
                    
                    // Info o trybie
                    if lockedString != nil {
                        lockedModeIndicator
                            .padding(.bottom, 12)
                    }
                    
                    guitarStringsBar
                        .padding(.bottom, 16)
                    
                    tunerSettingsSection
                        .padding(.bottom, 8)
                }
            }
            .navigationTitle("Stroik")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Wróć")
                                .font(.system(size: 16))
                        }
                        .foregroundStyle(.orange)
                    }
                }

            }
            .onAppear { engine.start() }
            .onDisappear { engine.stop() }
        }
    }
    
    // MARK: - Oblicz notę dla zablokowanej struny
    
    private func calculateNoteForLockedString(_ string: GuitarString, frequency: Float) -> DetectedNote {
        let targetFreq = string.frequency
        let semitones: Float = 12.0 * log2f(frequency / targetFreq)
        let centsOff: Float = semitones * 100.0
        
        return DetectedNote(
            name: string.noteName,
            octave: string.octave,
            frequency: frequency,
            centsOff: centsOff,
            guitarString: string.number
        )
    }
    
    // MARK: - Indicator trybu zablokowanego
    
    private var lockedModeIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 11))
            Text("Tryb ręczny: \(lockedString?.note ?? "")")
                .font(.system(size: 12, weight: .medium))
            Text("• dotknij strunę aby odblokować")
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(AppTheme.chordButtonBackground(for: colorScheme))
        )
    }
    
    // MARK: - Aktywny odczyt
    
    private func activeReadingView(note: DetectedNote) -> some View {
        VStack(spacing: 24) {
            TunerGaugeView(centsOff: note.centsOff)
                .padding(.horizontal, 32)
            
            Text(note.name)
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundStyle(noteColor(for: note))
                .shadow(color: noteColor(for: note).opacity(note.isInTune ? 0.6 : 0), radius: 12)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.1), value: note.name)
            
            Text("oktawa \(note.octave)")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            
            HStack(spacing: 16) {
                frequencyBadge(
                    label: String(format: "%.1f Hz", engine.currentFrequency),
                    icon: "waveform"
                )
                
                frequencyBadge(
                    label: centsText(note.centsOff),
                    icon: abs(note.centsOff) < 1 ? "checkmark" : (note.centsOff < 0 ? "chevron.down" : "chevron.up")
                )
            }
        }
    }
    
    // MARK: - Stan oczekiwania
    
    private var waitingForSignalView: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 56))
                .foregroundStyle(.orange.opacity(0.4))
                .symbolEffect(.pulse)
            
            Text("Zagraj dźwięk…")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            
            Text(lockedString != nil
                 ? "Strój strunę \(lockedString!.note)"
                 : "Lub wybierz strunę poniżej")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme).opacity(0.6))
        }
    }
    
    // MARK: - Brak mikrofonu
    
    private var noMicrophoneView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash")
                .font(.system(size: 56))
                .foregroundStyle(.red.opacity(0.5))
            
            Text("Brak dostępu do mikrofonu")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            
            Text("Włącz mikrofon w Ustawieniach iPhone'a")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                .multilineTextAlignment(.center)
            
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Otwórz Ustawienia")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.orange))
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Pasek strun gitary (klikalny)
    
    private var guitarStringsBar: some View {
        VStack(spacing: 10) {
            Rectangle()
                .fill(AppTheme.separator(for: colorScheme))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            HStack(spacing: 0) {
                ForEach(GuitarString.standard, id: \.number) { string in
                    let isLocked = lockedString?.number == string.number
                    let isDetected = !isLocked && (engine.currentNote?.guitarString == string.number || displayNote?.guitarString == string.number)
                    let isInTune = (isDetected || isLocked) && (displayNote?.isInTune ?? false)
                    
                    GuitarStringCell(
                        string: string,
                        isDetected: isDetected,
                        isLocked: isLocked,
                        isInTune: isInTune
                    )
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if lockedString?.number == string.number {
                                // Odblokuj
                                lockedString = nil
                            } else {
                                // Zablokuj na tej strunie
                                lockedString = string
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            
            Text("Dotknij strunę aby ją wybrać ręcznie")
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme).opacity(0.5))
        }
    }
    
    // MARK: - Ustawienia
    
    private var tunerSettingsSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.separator(for: colorScheme))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            HStack {
                Image(systemName: "tuningfork")
                    .font(.caption)
                    .foregroundStyle(.orange)
                
                Text("A4")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        engine.referenceA4 = max(420, engine.referenceA4 - 1)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.orange)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle().fill(AppTheme.chordButtonBackground(for: colorScheme))
                            )
                    }
                    
                    Text("\(Int(engine.referenceA4)) Hz")
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        .frame(width: 60)
                    
                    Button {
                        engine.referenceA4 = min(460, engine.referenceA4 + 1)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.orange)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle().fill(AppTheme.chordButtonBackground(for: colorScheme))
                            )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Pomocnicze
    
    private func noteColor(for note: DetectedNote) -> Color {
        if note.isInTune { return .green }
        if note.isClose  { return .orange }
        return .red
    }
    
    private func centsText(_ cents: Float) -> String {
        if abs(cents) < 1 { return "✓ czysto" }
        let sign = cents > 0 ? "+" : ""
        return "\(sign)\(Int(cents)) ¢"
    }
    
    private func frequencyBadge(label: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
        }
        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(AppTheme.inputBackground(for: colorScheme))
        )
    }
}

// MARK: - Wskaźnik odchylenia (gauge)

struct TunerGaugeView: View {
    let centsOff: Float
    @Environment(\.colorScheme) private var colorScheme
    
    private var normalizedOffset: CGFloat {
        CGFloat(max(-50, min(50, centsOff))) / 50.0
    }
    
    private var indicatorColor: Color {
        let absCents = abs(centsOff)
        if absCents < 5  { return .green }
        if absCents < 15 { return .orange }
        return .red
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("♭")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                Spacer()
                Text("♯")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            }
            
            GeometryReader { geo in
                let width = geo.size.width
                let centerX = width / 2
                let indicatorX = centerX + normalizedOffset * centerX
                
                ZStack {
                    Capsule()
                        .fill(AppTheme.inputBackground(for: colorScheme))
                        .frame(height: 6)
                    
                    ForEach([-1.0, -0.5, 0.0, 0.5, 1.0], id: \.self) { tick in
                        let x = centerX + CGFloat(tick) * centerX
                        let isCenter = tick == 0
                        
                        RoundedRectangle(cornerRadius: 1)
                            .fill(isCenter
                                  ? AppTheme.primaryText(for: colorScheme).opacity(0.6)
                                  : AppTheme.secondaryText(for: colorScheme).opacity(0.3))
                            .frame(width: isCenter ? 2 : 1, height: isCenter ? 24 : 14)
                            .position(x: x, y: geo.size.height / 2)
                    }
                    
                    Circle()
                        .fill(indicatorColor)
                        .frame(width: 20, height: 20)
                        .shadow(color: indicatorColor.opacity(0.5), radius: 6)
                        .position(x: indicatorX, y: geo.size.height / 2)
                        .animation(.linear(duration: 0.05), value: centsOff)
                }
            }
            .frame(height: 30)
        }
    }
}

// MARK: - Model struny gitary (z częstotliwością)

struct GuitarString: Equatable {
    let number: Int       // 6 (najgrubsza) … 1 (najcieńsza)
    let note: String      // np. "E2"
    let noteName: String  // np. "E"
    let octave: Int       // np. 2
    let frequency: Float  // częstotliwość idealna (A4=440Hz)
    
    static let standard: [GuitarString] = [
        GuitarString(number: 6, note: "E2", noteName: "E", octave: 2, frequency: 82.41),
        GuitarString(number: 5, note: "A2", noteName: "A", octave: 2, frequency: 110.00),
        GuitarString(number: 4, note: "D3", noteName: "D", octave: 3, frequency: 146.83),
        GuitarString(number: 3, note: "G3", noteName: "G", octave: 3, frequency: 196.00),
        GuitarString(number: 2, note: "B3", noteName: "B", octave: 3, frequency: 246.94),
        GuitarString(number: 1, note: "E4", noteName: "E", octave: 4, frequency: 329.63),
    ]
}

// MARK: - Komórka struny (z obsługą locked state)

struct GuitarStringCell: View {
    let string: GuitarString
    let isDetected: Bool
    let isLocked: Bool
    let isInTune: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    private var accentColor: Color {
        if isLocked { return .blue }
        if !isDetected { return AppTheme.secondaryText(for: colorScheme).opacity(0.4) }
        return isInTune ? .green : .orange
    }
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isDetected || isLocked ? accentColor : .clear)
                    .overlay(
                        Circle()
                            .stroke(accentColor, lineWidth: isDetected || isLocked ? 0 : 1.5)
                    )
                    .frame(width: 28, height: 28)
                
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            
            Text(string.note)
                .font(.system(size: 13, weight: isDetected || isLocked ? .bold : .medium, design: .monospaced))
                .foregroundStyle(isDetected || isLocked ? accentColor : AppTheme.secondaryText(for: colorScheme))
        }
        .padding(.vertical, 4)
    }
}

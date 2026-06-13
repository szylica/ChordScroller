import AudioKit
import AudioKitEX
import SoundpipeAudioKit
import AVFoundation
import Combine

// MARK: - Model wykrytej nuty

struct DetectedNote: Equatable {
    let name: String
    let octave: Int
    let frequency: Float
    let centsOff: Float
    let guitarString: Int?
    
    var fullName: String { "\(name)\(octave)" }
    var isInTune: Bool { abs(centsOff) < 5 }
    var isClose: Bool { abs(centsOff) < 15 }
}

// MARK: - Silnik stroika (AudioKit)

final class TunerEngine: ObservableObject {
    
    // MARK: - Stan publikowany do UI
    
    @Published private(set) var isActive = false
    @Published private(set) var currentNote: DetectedNote?
    @Published private(set) var currentFrequency: Float = 0
    @Published private(set) var hasLiveSignal = false
    @Published var referenceA4: Float = 440.0
    
    // MARK: - AudioKit
    
    let engine = AudioEngine()
    private var mic: AudioEngine.InputNode!
    private var silence: Fader!
    private var tracker: PitchTap!
    private var engineRunning = false
    
    // MARK: - Podtrzymanie odczytu
    
    private var holdTimer: Timer?
    private var dimTimer: Timer?
    private let holdDuration: TimeInterval = 3.5
    private let dimDelay: TimeInterval = 0.4
    
    /// Próg amplitudy – poniżej ignorujemy (szum)
    private let amplitudeThreshold: Float = 0.02
    
    // MARK: - Wygładzanie
    
    private let smoothingFactor: Float = 0.25
    private var smoothedFrequency: Float = 0
    
    // MARK: - Stałe muzyczne
    
    private static let noteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    
    private static let guitarStrings: [(string: Int, note: String, octave: Int)] = [
        (6, "E", 2), (5, "A", 2), (4, "D", 3),
        (3, "G", 3), (2, "B", 3), (1, "E", 4)
    ]
    
    // MARK: - Lifecycle
    
    deinit {
        stop()
    }
    
    // MARK: - Publiczne API
    
    func start() {
        guard !isActive else { return }
        
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard granted else { return }
                self?.startAudioEngine()
            }
        }
    }
    
    func stop() {
        tracker?.stop()
        if engineRunning {
            engine.stop()
            engineRunning = false
        }
        holdTimer?.invalidate()
        dimTimer?.invalidate()
        holdTimer = nil
        dimTimer = nil
        smoothedFrequency = 0
        
        DispatchQueue.main.async { [weak self] in
            self?.isActive = false
            self?.currentNote = nil
            self?.currentFrequency = 0
            self?.hasLiveSignal = false
        }
    }
    
    // MARK: - Konfiguracja AudioKit
    
    private func startAudioEngine() {
        // 1. Uzyskaj dostęp do mikrofonu
        guard let input = engine.input else {
            print("[TunerEngine] Brak dostępu do wejścia audio")
            return
        }
        mic = input
        
        // 2. Fader z gain=0 – wycisza mikrofon na wyjściu
        //    (AudioKit wymaga engine.output żeby cokolwiek przetwarzać)
        silence = Fader(mic, gain: 0)
        engine.output = silence
        
        // 3. PitchTap na mikrofonie
        tracker = PitchTap(mic) { [weak self] pitch, amp in
            // pitch[0] = częstotliwość lewego kanału
            // amp[0] = amplituda lewego kanału
            DispatchQueue.main.async {
                self?.handlePitchUpdate(
                    frequency: pitch[0],
                    amplitude: amp[0]
                )
            }
        }
        
        // 4. Start
        do {
            try engine.start()
            engineRunning = true
            tracker.start()
            isActive = true
        } catch {
            print("[TunerEngine] Błąd startu: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Obsługa odczytów z PitchTap
    
    private func handlePitchUpdate(frequency: Float, amplitude: Float) {
        // Za cicho → podtrzymanie
        guard amplitude > amplitudeThreshold else {
            startHoldCountdown()
            return
        }
        
        // Za niska/wysoka częstotliwość → ignoruj
        guard frequency > 60, frequency < 1400 else {
            startHoldCountdown()
            return
        }
        
        // Mamy sygnał – anuluj timery podtrzymania
        holdTimer?.invalidate()
        holdTimer = nil
        dimTimer?.invalidate()
        dimTimer = nil
        
        let smoothed = applySmoothing(frequency)
        let note = identifyNote(frequency: smoothed)
        
        currentFrequency = smoothed
        currentNote = note
        hasLiveSignal = true
    }
    
    // MARK: - Podtrzymanie odczytu
    
    private func startHoldCountdown() {
        if dimTimer == nil {
            dimTimer = Timer.scheduledTimer(withTimeInterval: dimDelay, repeats: false) { [weak self] _ in
                self?.hasLiveSignal = false
            }
        }
        
        if holdTimer == nil {
            holdTimer = Timer.scheduledTimer(withTimeInterval: holdDuration, repeats: false) { [weak self] _ in
                self?.currentNote = nil
                self?.currentFrequency = 0
                self?.hasLiveSignal = false
                self?.smoothedFrequency = 0
            }
        }
    }
    
    // MARK: - Wygładzanie
    
    private func applySmoothing(_ frequency: Float) -> Float {
        if smoothedFrequency == 0 {
            smoothedFrequency = frequency
        } else {
            let ratio = frequency / smoothedFrequency
            if ratio > 0.94 && ratio < 1.06 {
                smoothedFrequency = smoothingFactor * smoothedFrequency + (1 - smoothingFactor) * frequency
            } else {
                smoothedFrequency = frequency
            }
        }
        return smoothedFrequency
    }
    
    // MARK: - Identyfikacja nuty
    
    private func identifyNote(frequency: Float) -> DetectedNote {
        let a4 = referenceA4
        let semitones: Float = 12.0 * log2f(frequency / a4)
        let rounded: Float = roundf(semitones)
        let centsOff: Float = (semitones - rounded) * 100.0
        
        let midiNote = 69 + Int(rounded)
        let noteIndex = ((midiNote % 12) + 12) % 12
        let octave = (midiNote / 12) - 1
        let noteName = Self.noteNames[noteIndex]
        
        let guitarString = Self.guitarStrings.first {
            $0.note == noteName && $0.octave == octave
        }?.string
        
        return DetectedNote(
            name: noteName,
            octave: octave,
            frequency: frequency,
            centsOff: centsOff,
            guitarString: guitarString
        )
    }
}

import SwiftUI
import UIKit

// MARK: - ScrollView z koordynacją ręcznego i automatycznego scrollowania

final class SmartScrollView: UIScrollView, UIScrollViewDelegate {
    
    // Callbacki do SwiftUI
    var onDragBegan: (() -> Void)?
    var onDragEnded: ((CGFloat) -> Void)?
    var onDidScroll: ((CGFloat) -> Void)?
    
    // Flagi
    private(set) var isUserDragging = false
    private(set) var isUserDecelerating = false
    
    /// Czy użytkownik aktualnie dotyka / ma rozpęd
    var isUserInteracting: Bool { isUserDragging || isUserDecelerating }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        showsVerticalScrollIndicator = true
        showsHorizontalScrollIndicator = false
        alwaysBounceVertical = true
        isScrollEnabled = true
        backgroundColor = .clear
        decelerationRate = .normal
    }
    required init?(coder: NSCoder) { fatalError() }
    
    /// Programowe ustawienie pozycji (ignorowane gdy user dotyka)
    func setProgrammaticOffset(_ y: CGFloat) {
        guard !isUserInteracting else { return }
        contentOffset = CGPoint(x: 0, y: max(0, y))
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserDragging = true
        onDragBegan?()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isUserDragging = false
        if !decelerate {
            isUserDecelerating = false
            onDragEnded?(scrollView.contentOffset.y)
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        isUserDecelerating = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isUserDecelerating = false
        onDragEnded?(scrollView.contentOffset.y)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isUserInteracting {
            onDidScroll?(scrollView.contentOffset.y)
        }
    }
}

// MARK: - UIViewRepresentable

struct TeleprompterScrollWrapper: UIViewRepresentable {
    let contentView: UIView
    @Binding var offset: CGFloat
    let isAutoScrolling: Bool
    let isDark: Bool
    var onContentHeight: (CGFloat) -> Void
    var onDragBegan: () -> Void
    var onDragEnded: (CGFloat) -> Void
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    class Coordinator {
        weak var scrollView: SmartScrollView?
    }
    
    func makeUIView(context: Context) -> SmartScrollView {
        let sv = SmartScrollView()
        context.coordinator.scrollView = sv
        sv.indicatorStyle = isDark ? .white : .black
        
        sv.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: sv.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: sv.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: sv.frameLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: sv.contentLayoutGuide.bottomAnchor),
        ])
        
        sv.onDragBegan = onDragBegan
        sv.onDragEnded = onDragEnded
        
        return sv
    }
    
    func updateUIView(_ sv: SmartScrollView, context: Context) {
        // Aktualizuj callbacki
        sv.onDragBegan = onDragBegan
        sv.onDragEnded = onDragEnded
        sv.indicatorStyle = isDark ? .white : .black
        
        // Zmierz content
        sv.layoutIfNeeded()
        DispatchQueue.main.async {
            self.onContentHeight(sv.contentSize.height)
        }
        
        // Ustaw offset programowo (SmartScrollView ignoruje gdy user dotyka)
        if isAutoScrolling {
            sv.setProgrammaticOffset(offset)
        } else if !sv.isUserInteracting {
            sv.setProgrammaticOffset(offset)
        }
    }
}

// MARK: - UIKit: tekst piosenki

final class TeleprompterLyricsView: UIView {
    private var topConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    
    init(content: String, fontSize: CGFloat, width: CGFloat, isDark: Bool) {
        super.init(frame: .zero)
        backgroundColor = .clear
        build(content: content, fontSize: fontSize, availableWidth: width, isDark: isDark)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func build(content: String, fontSize: CGFloat, availableWidth: CGFloat, isDark: Bool) {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = fontSize * 0.7
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        
        let top = stack.topAnchor.constraint(equalTo: topAnchor, constant: 300)
        let bot = stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -300)
        NSLayoutConstraint.activate([
            top,
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            bot
        ])
        topConstraint = top
        bottomConstraint = bot
        
        let textColor: UIColor = isDark ? .white : .black
        let lines = ChordFormatter.parseContent(content)
        let usable = max(availableWidth - 32, 100)
        
        for line in lines {
            if line.isEmpty {
                let spacer = UIView()
                spacer.translatesAutoresizingMaskIntoConstraints = false
                spacer.widthAnchor.constraint(equalToConstant: usable).isActive = true
                spacer.heightAnchor.constraint(equalToConstant: fontSize * 0.4).isActive = true
                stack.addArrangedSubview(spacer)
            } else if line.hasChords {
                let lv = buildFlowLine(segments: line.segments, fontSize: fontSize, maxW: usable, textColor: textColor)
                stack.addArrangedSubview(lv)
            } else {
                let lbl = UILabel()
                lbl.text = line.rawText
                lbl.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
                lbl.textColor = textColor
                lbl.numberOfLines = 0
                lbl.lineBreakMode = .byWordWrapping
                stack.addArrangedSubview(lbl)
            }
        }
    }
    
    private func buildFlowLine(segments: [ChordSegment], fontSize: CGFloat, maxW: CGFloat, textColor: UIColor) -> UIView {
        let chordFont = UIFont.monospacedSystemFont(ofSize: fontSize * 0.82, weight: .bold)
        let textFont  = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let chordH = ceil(chordFont.lineHeight)
        let textH  = ceil(textFont.lineHeight)
        let gap: CGFloat = 2
        let segH = chordH + gap + textH
        let lineGap = fontSize * 0.5
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        var x: CGFloat = 0
        var y: CGFloat = 0
        
        for seg in segments {
            let chordStr = seg.chord ?? ""
            let textStr  = seg.text
            
            let cw = chordStr.isEmpty ? 0 :
                ceil((chordStr as NSString).size(withAttributes: [.font: chordFont]).width)
            let tw = textStr.isEmpty ? 0 :
                ceil((textStr as NSString).size(withAttributes: [.font: textFont]).width)
            let segW = max(cw, tw, 1)
            
            if segW < 1 { continue }
            
            if x > 0 && x + segW > maxW {
                x = 0
                y += segH + lineGap
            }
            
            // Akord
            let cl = UILabel()
            cl.text = chordStr.isEmpty ? "" : chordStr
            cl.font = chordFont
            cl.textColor = chordStr.isEmpty ? .clear : .systemOrange
            cl.frame = CGRect(x: x, y: y, width: segW, height: chordH)
            container.addSubview(cl)
            
            // Tekst
            let tl = UILabel()
            tl.text = textStr
            tl.font = textFont
            tl.textColor = textColor
            tl.frame = CGRect(x: x, y: y + chordH + gap, width: segW, height: textH)
            container.addSubview(tl)
            
            x += segW
        }
        
        let totalH = y + segH
        container.widthAnchor.constraint(equalToConstant: maxW).isActive = true
        container.heightAnchor.constraint(equalToConstant: totalH).isActive = true
        return container
    }
    
    func applyScreenHeight(_ h: CGFloat) {
        let indicatorY = h * 0.25
        topConstraint?.constant = indicatorY
        bottomConstraint?.constant = -(h - indicatorY)
        setNeedsLayout()
        layoutIfNeeded()
    }
}

// MARK: - Główny widok telepromptera

struct TeleprompterView: View {
    let song: Song
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var viewHeight: CGFloat = 0
    @State private var isPlaying = false
    @State private var speed: Double
    @State private var showControls = true
    @State private var timer: Timer?
    @State private var hideTimer: Timer?
    @State private var lyricsView: TeleprompterLyricsView?
    @State private var toastMessage: String?
    @State private var wasPlayingBeforeDrag = false

    init(song: Song) {
        self.song = song
        _speed = State(initialValue: song.scrollSpeed)
    }
    
    private var isDark: Bool { colorScheme == .dark }
    private var bgColor: Color { AppTheme.background(for: colorScheme) }
    private var textColor: Color { AppTheme.primaryText(for: colorScheme) }
    private var secondaryColor: Color { AppTheme.secondaryText(for: colorScheme) }
    private var overlayBtnBg: Color { isDark ? .white.opacity(0.15) : .black.opacity(0.08) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                bgColor.ignoresSafeArea()

                if let lv = lyricsView {
                    TeleprompterScrollWrapper(
                        contentView: lv,
                        offset: $scrollOffset,
                        isAutoScrolling: isPlaying,
                        isDark: isDark,
                        onContentHeight: { contentHeight = $0 },
                        onDragBegan: handleDragBegan,
                        onDragEnded: handleDragEnded
                    )
                    .ignoresSafeArea()
                }

                // Gradienty
                LinearGradient(colors: [bgColor, .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 80).allowsHitTesting(false)
                VStack {
                    Spacer()
                    LinearGradient(colors: [.clear, bgColor], startPoint: .top, endPoint: .bottom)
                        .frame(height: 100).allowsHitTesting(false)
                }

                // Linia wskaźnikowa
                VStack {
                    Rectangle()
                        .fill(Color.orange.opacity(0.6))
                        .frame(height: 2)
                        .shadow(color: .orange.opacity(0.4), radius: 4)
                        .padding(.top, geo.size.height * 0.25)
                    Spacer()
                }
                .allowsHitTesting(false)
                
                // Toast
                if let msg = toastMessage {
                    VStack {
                        Text(msg)
                            .font(.caption).fontWeight(.medium)
                            .foregroundStyle(textColor)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(Capsule().fill(bgColor.opacity(0.85)))
                            .padding(.top, geo.size.height * 0.25 + 16)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }

                // Tap na ekran (gdy kontrolki ukryte - pokaż je)
                if !showControls {
                    Color.clear.contentShape(Rectangle()).ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.22)) { showControls = true }
                            scheduleHide()
                        }
                }

                // Kontrolki
                if showControls {
                    controlsOverlay(geo: geo)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .onAppear {
                viewHeight = geo.size.height
                lyricsView = TeleprompterLyricsView(
                    content: song.content,
                    fontSize: song.fontSize,
                    width: geo.size.width,
                    isDark: isDark
                )
                lyricsView?.applyScreenHeight(geo.size.height)
                if settings.settings.keepScreenAwake {
                    UIApplication.shared.isIdleTimerDisabled = true
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onDisappear {
            stopTimer()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // MARK: - Kontrolki
    
    private func controlsOverlay(geo: GeometryProxy) -> some View {
        VStack {
            // Górny pasek
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.title3).fontWeight(.semibold)
                        .foregroundStyle(textColor).padding(12)
                        .background(Circle().fill(overlayBtnBg))
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(song.title.isEmpty ? L10n.untitled.localized() : song.title)
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(textColor.opacity(0.85)).lineLimit(1)
                    
                    // Procent postępu
                    if contentHeight > viewHeight {
                        let progress = min(scrollOffset / (contentHeight - viewHeight), 1.0)
                        Text("\(Int(progress * 100))%")
                            .font(.caption2).foregroundStyle(.orange)
                    }
                }
                
                Spacer()
                
                Button { resetScroll() } label: {
                    Image(systemName: "arrow.counterclockwise").font(.title3)
                        .foregroundStyle(textColor).padding(12)
                        .background(Circle().fill(overlayBtnBg))
                }
            }
            .padding(.horizontal, 20).padding(.top, 60)
            
            Spacer()
            
            // Dolny panel
            VStack(spacing: 20) {
                // Tempo
                VStack(spacing: 8) {
                    HStack {
                        Text(L10n.tempo.localized()).font(.caption).foregroundStyle(secondaryColor)
                        Spacer()
                        Text("\(Int(speed)) px/s")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(.orange)
                    }
                    
                    HStack(spacing: 12) {
                        Button { adjustSpeed(-5) } label: {
                            Image(systemName: "minus").font(.caption).fontWeight(.bold)
                                .foregroundStyle(textColor).frame(width: 32, height: 32)
                                .background(Circle().fill(overlayBtnBg))
                        }
                        
                        Slider(value: $speed, in: 10...200, step: 5).tint(.orange)
                            .onChange(of: speed) { _, _ in if isPlaying { restartTimer() } }
                        
                        Button { adjustSpeed(5) } label: {
                            Image(systemName: "plus").font(.caption).fontWeight(.bold)
                                .foregroundStyle(textColor).frame(width: 32, height: 32)
                                .background(Circle().fill(overlayBtnBg))
                        }
                    }
                }
                
                // Play / Pause
                Button { togglePlay() } label: {
                    HStack(spacing: 12) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                        Text(isPlaying ? L10n.pause.localized() : L10n.play.localized())
                            .font(.headline).fontWeight(.semibold)
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16).fill(Color.orange)
                    )
                }
                
                // Info
                HStack(spacing: 16) {
                    Image(systemName: "hand.draw").foregroundStyle(.orange.opacity(0.7))
                    Text(L10n.scrollHint.localized())
                        .font(.caption).foregroundStyle(secondaryColor)
                }
            }
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 28).fill(isDark ? .ultraThinMaterial : .regularMaterial))
            .padding(.horizontal, 16).padding(.bottom, 40)
        }
        .ignoresSafeArea()
        // Tap na kontrolki żeby je ukryć
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.22)) { showControls = false }
        }
    }

    // MARK: - Ręczne przewijanie
    
    private func handleDragBegan() {
        wasPlayingBeforeDrag = isPlaying
        
        if settings.settings.stopScrollOnManualScroll {
            if isPlaying {
                stopTimer()
                showToast(L10n.pausedToast.localized())
            }
        } else {
            // Tymczasowo wstrzymaj timer (żeby nie walczył z palcem)
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func handleDragEnded(_ newOffset: CGFloat) {
        scrollOffset = max(0, newOffset)
        
        if settings.settings.stopScrollOnManualScroll {
            // Nie wznawiaj - user musi kliknąć play
        } else {
            // Kontynuuj od nowej pozycji
            if wasPlayingBeforeDrag {
                isPlaying = true
                restartTimer()
            }
        }
    }
    
    private func showToast(_ text: String) {
        withAnimation(.easeInOut(duration: 0.2)) { toastMessage = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) { toastMessage = nil }
        }
    }
    
    // MARK: - Logika
    
    private func adjustSpeed(_ delta: Double) {
        speed = max(10, min(200, speed + delta))
        if isPlaying { restartTimer() }
    }
    
    private func togglePlay() {
        isPlaying ? stopTimer() : startTimer()
        scheduleHide()
    }
    
    private func startTimer() {
        isPlaying = true
        restartTimer()
    }
    
    private func stopTimer() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }
    
    private func restartTimer() {
        timer?.invalidate()
        let dt = 1.0 / 60.0
        let step = speed * dt
        timer = Timer.scheduledTimer(withTimeInterval: dt, repeats: true) { _ in
            let maxOff = max(0, contentHeight - viewHeight)
            if scrollOffset < maxOff {
                scrollOffset = min(scrollOffset + step, maxOff)
            } else {
                stopTimer()
            }
        }
    }
    
    private func resetScroll() {
        stopTimer()
        scrollOffset = 0
    }
    
    private func scheduleHide() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { _ in
            if isPlaying {
                withAnimation(.easeInOut(duration: 0.35)) { showControls = false }
            }
        }
    }
}

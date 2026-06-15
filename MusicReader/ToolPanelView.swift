import SwiftUI

// MARK: - Opcje menu bocznego

enum ToolMenuItem: String, Identifiable {
    case tuner
    case settings
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .tuner:    return L10n.tuner.localized()
        case .settings: return L10n.settings.localized()
        }
    }
    
    var icon: String {
        switch self {
        case .tuner:    return "tuningfork"
        case .settings: return "gearshape"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .tuner:    return .orange
        case .settings: return .gray
        }
    }
    
    var subtitle: String {
        switch self {
        case .tuner:    return L10n.tunerSubtitle.localized()
        case .settings: return L10n.settingsSubtitle.localized()
        }
    }
    
    /// Narzędzia wyświetlane w głównej liście (bez ustawień)
    static let tools: [ToolMenuItem] = [.tuner]
}

// MARK: - Panel boczny (wysuwany z lewej)

struct ToolPanelView: View {
    @Binding var isPresented: Bool
    let onSelect: (ToolMenuItem) -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var dragOffset: CGFloat = 0
    
    /// Szerokość panelu – 72% ekranu, max 300pt
    private var panelWidth: CGFloat {
        min(UIScreen.main.bounds.width * 0.72, 300)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Przyciemnione tło
            if isPresented {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture { close() }
                    .transition(.opacity)
            }
            
            // Panel
            HStack(spacing: 0) {
                panelContent
                    .frame(width: panelWidth)
                    .background(AppTheme.background(for: colorScheme))
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 20,
                            topTrailingRadius: 20
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 5)
                    .offset(x: isPresented ? dragOffset : -panelWidth)
                    .gesture(panelDragGesture)
                
                Spacer()
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isPresented)
    }
    
    // MARK: - Zawartość panelu
    
    private var panelContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Nagłówek
            header
            
            Rectangle()
                .fill(AppTheme.separator(for: colorScheme))
                .frame(height: 1)
                .padding(.horizontal, 16)
            
            // Lista narzędzi
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(ToolMenuItem.tools) { item in
                        menuButton(for: item)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            
            Spacer()
            
            // Ustawienia na dole
            VStack(spacing: 0) {
                Rectangle()
                    .fill(AppTheme.separator(for: colorScheme))
                    .frame(height: 1)
                    .padding(.horizontal, 16)
                
                menuButton(for: .settings)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            
            // Stopka
            footer
        }
    }
    
    // MARK: - Nagłówek
    
    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "guitars")
                    .font(.title3)
                    .foregroundStyle(.orange)
                Text("ChordScroller")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            }
            
            Spacer()
            
            Button { close() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    .frame(width: 30, height: 30)
                    .background(
                        Circle().fill(AppTheme.inputBackground(for: colorScheme))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }
    
    // MARK: - Przycisk opcji menu
    
    private func menuButton(for item: ToolMenuItem) -> some View {
        Button {
            close()
            // Lekkie opóźnienie żeby panel zdążył się zamknąć
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onSelect(item)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(item.iconColor)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    
                    Text(item.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme).opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardBackground(for: colorScheme))
            )
        }
    }
    
    // MARK: - Stopka
    
    private var footer: some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(AppTheme.separator(for: colorScheme))
                .frame(height: 1)
                .padding(.horizontal, 16)
            
            Text("v1.0.0")
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme).opacity(0.4))
                .padding(.vertical, 10)
        }
    }
    
    // MARK: - Gesty i akcje
    
    private var panelDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.width < 0 {
                    dragOffset = value.translation.width
                }
            }
            .onEnded { value in
                if value.translation.width < -80 || value.predictedEndTranslation.width < -120 {
                    close()
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    dragOffset = 0
                }
            }
    }
    
    private func close() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isPresented = false
        }
        dragOffset = 0
    }
}

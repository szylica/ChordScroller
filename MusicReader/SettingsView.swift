import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Sekcja wyglądu
                        settingsSection(title: "Wygląd", icon: "paintbrush") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Motyw kolorystyczny")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                
                                HStack(spacing: 12) {
                                    ForEach(AppColorScheme.allCases, id: \.self) { scheme in
                                        ColorSchemeButton(
                                            scheme: scheme,
                                            isSelected: settingsManager.settings.colorScheme == scheme
                                        ) {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                settingsManager.settings.colorScheme = scheme
                                            }
                                        }
                                    }
                                }
                                
                                Text(colorSchemeDescription)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                                    .padding(.top, 4)
                            }
                        }
                        
                        // Sekcja telepromptera
                        settingsSection(title: "Teleprompter", icon: "play.rectangle") {
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Po ręcznym przewinięciu:")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                    
                                    Picker("Zachowanie", selection: $settingsManager.settings.stopScrollOnManualScroll) {
                                        Text("Zatrzymaj auto-scroll").tag(true)
                                        Text("Kontynuuj auto-scroll").tag(false)
                                    }
                                    .pickerStyle(.segmented)
                                    
                                    Text(settingsManager.settings.stopScrollOnManualScroll
                                         ? "Przewijanie automatyczne zatrzyma się gdy przewiniesz ręcznie. Naciśnij play aby wznowić."
                                         : "Przewijanie automatyczne będzie kontynuowane od nowej pozycji po ręcznym przewinięciu.")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                                }
                                
                                Divider().background(AppTheme.separator(for: colorScheme))
                                
                                Toggle(isOn: $settingsManager.settings.keepScreenAwake) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Nie wyłączaj ekranu")
                                            .font(.subheadline)
                                            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                        Text("Ekran pozostanie włączony podczas telepromptera")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                                    }
                                }
                                .tint(.orange)
                            }
                        }
                        
                        // Sekcja informacji
                        settingsSection(title: "Informacje", icon: "info.circle") {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Wersja aplikacji").foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                    Spacer()
                                    Text("1.0.0").foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                                }
                                .font(.subheadline)
                                
                                Divider().background(AppTheme.separator(for: colorScheme))
                                
                                HStack {
                                    Text("Akordy w bazie").foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                    Spacer()
                                    Text("50+").foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                                }
                                .font(.subheadline)
                            }
                        }
                        
                        Button {
                            settingsManager.reset()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Przywróć domyślne ustawienia")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                            )
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Ustawienia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Gotowe") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
    
    private var colorSchemeDescription: String {
        switch settingsManager.settings.colorScheme {
        case .system: return "Aplikacja automatycznie dostosuje się do ustawień systemowych."
        case .light: return "Jasny motyw z białym tłem."
        case .dark: return "Ciemny motyw z czarnym tłem (domyślny)."
        }
    }
    
    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardBackground(for: colorScheme))
            )
        }
    }
}

// MARK: - Przycisk wyboru motywu

struct ColorSchemeButton: View {
    let scheme: AppColorScheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Group {
                        switch scheme {
                        case .light:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(white: 0.92))
                        case .dark:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(white: 0.12))
                        case .system:
                            HStack(spacing: 0) {
                                Color(white: 0.92)
                                Color(white: 0.12)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .frame(width: 64, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.orange : Color.gray.opacity(0.3), lineWidth: isSelected ? 2.5 : 1)
                    )
                    
                    Image(systemName: scheme.icon)
                        .font(.title3)
                        .foregroundStyle(scheme == .dark ? .yellow : .orange)
                }
                
                Text(scheme.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .orange : .gray)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

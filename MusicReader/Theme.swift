import SwiftUI

// MARK: - Kolory adaptacyjne zależne od motywu

struct AppTheme {
    
    // Główne tło aplikacji
    static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.07, green: 0.07, blue: 0.09)
            : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    // Tło kart / kafelków
    static func cardBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.12, green: 0.12, blue: 0.15)
            : Color.white
    }
    
    // Tło pól tekstowych / inputów
    static func inputBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.15, green: 0.15, blue: 0.18)
            : Color(red: 0.93, green: 0.93, blue: 0.95)
    }
    
    // Główny kolor tekstu
    static func primaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : .black
    }
    
    // Drugorzędny kolor tekstu
    static func secondaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.gray
            : Color(red: 0.4, green: 0.4, blue: 0.45)
    }
    
    // Kolor separatora
    static func separator(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.gray.opacity(0.2)
            : Color.gray.opacity(0.3)
    }
    
    // Tło wiersza listy
    static func listRowBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.12, green: 0.12, blue: 0.15)
            : Color.white
    }
    
    // Tło nieaktywnego przycisku
    static func inactiveButton(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.2, green: 0.2, blue: 0.24)
            : Color(red: 0.88, green: 0.88, blue: 0.9)
    }
    
    // Tło akordów
    static func chordButtonBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.22, green: 0.14, blue: 0.08)
            : Color.orange.opacity(0.12)
    }
}

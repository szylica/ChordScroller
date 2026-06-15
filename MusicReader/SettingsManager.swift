import SwiftUI
import Combine

// MARK: - Motyw kolorystyczny

enum AppColorScheme: String, Codable, CaseIterable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"

    var displayName: String {
        switch self {
        case .system: return L10n.systemTheme.localized()
        case .light:  return L10n.lightTheme.localized()
        case .dark:   return L10n.darkTheme.localized()
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

// MARK: - Model ustawień

struct AppSettings: Codable {
    var stopScrollOnManualScroll: Bool  = true
    var keepScreenAwake: Bool           = true
    var colorScheme: AppColorScheme     = .dark
    var language: AppLanguage           = .system

    static let `default` = AppSettings()
}

// MARK: - Manager ustawień

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var settings: AppSettings {
        didSet { save() }
    }

    /// Aktualnie aktywny język – zawsze konkretny (nigdy .system)
    var resolvedLanguage: AppLanguage {
        AppLanguage.resolve(settings.language)
    }

    private let saveKey = "app_settings"

    private init() {
        if let data    = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .default
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    func reset() {
        settings = .default
    }
}

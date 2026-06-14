import SwiftUI

@main
struct ChordScrollerApp: App {
    @StateObject private var settingsManager = SettingsManager.shared
    @Environment(\.colorScheme) private var systemScheme
    
    private var effectiveScheme: ColorScheme {
        AppTheme.resolveColorScheme(
            appScheme: settingsManager.settings.colorScheme,
            systemScheme: systemScheme
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(settingsManager.settings.colorScheme.colorScheme)
                .environment(\.effectiveColorScheme, effectiveScheme)
        }
    }
}

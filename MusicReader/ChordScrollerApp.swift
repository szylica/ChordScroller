import SwiftUI

@main
struct ChordScrollerApp: App {
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(settingsManager.settings.colorScheme.colorScheme)
        }
    }
}

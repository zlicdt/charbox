import SwiftUI

@main
struct CharboxApp: App {
    @StateObject private var chatManager = ChatManager()
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(chatManager)
                .environmentObject(settingsManager)
        }
    }
}

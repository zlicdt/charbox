import SwiftUI

struct ContentView: View {
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingSettings = false
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧边栏：对话记忆列表和功能选择
            SidebarView(showingSettings: $showingSettings)
                .frame(width: 280)
                .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // 右侧主视图：当前对话
            ChatView()
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(settingsManager)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ChatManager())
        .environmentObject(SettingsManager())
}

//
//  ContentView.swift
//  CharBox
//
//  Created by zlicdt on 2025/8/4.
//  Copyright © 2025 zlicdt. All rights reserved.
//  
//  This file is part of CharBox.
//  
//  CharBox is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//  
//  CharBox is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//  
//  You should have received a copy of the GNU General Public License
//  along with CharBox. If not, see <https://www.gnu.org/licenses/>.
//

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

//
//  SettingsManager.swift
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

import Foundation
import Combine

class SettingsManager: ObservableObject {
    @Published var settings: ChatSettings
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "ChatSettings"
    
    init() {
        if let data = userDefaults.data(forKey: settingsKey),
           let decodedSettings = try? JSONDecoder().decode(ChatSettings.self, from: data) {
            settings = decodedSettings
        } else {
            settings = ChatSettings()
        }
    }
    
    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: settingsKey)
        }
    }
    
    func updateProvider(_ provider: APIProvider) {
        settings.apiProvider = provider
        // 当更换提供商时，自动选择第一个可用模型
        if !provider.models.isEmpty {
            settings.selectedModel = provider.models[0]
        }
        saveSettings()
    }
    
    func updateModel(_ model: String) {
        settings.selectedModel = model
        saveSettings()
    }
    
    func updateAPIKey(_ key: String) {
        settings.apiKey = key
        saveSettings()
    }
    
    func updateTemperature(_ temperature: Double) {
        settings.temperature = temperature
        saveSettings()
    }
    
    func updateSystemPrompt(_ prompt: String) {
        settings.systemPrompt = prompt
        saveSettings()
    }
    
    func updateMaxTokens(_ tokens: Int) {
        settings.maxTokens = tokens
        saveSettings()
    }
}

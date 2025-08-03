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

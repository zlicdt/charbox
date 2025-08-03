import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) var dismiss // 使用新的 dismiss 环境变量
    
    var body: some View {
        NavigationStack { // 使用 NavigationStack 替代 NavigationView
            Form {
                // API 供应商设置
                Section("API 供应商") {
                    Picker("供应商", selection: Binding(
                        get: { settingsManager.settings.apiProvider },
                        set: { settingsManager.updateProvider($0) }
                    )) {
                        ForEach(APIProvider.allCases, id: \.self) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    SecureField("API Key", text: Binding(
                        get: { settingsManager.settings.apiKey },
                        set: { settingsManager.updateAPIKey($0) }
                    ))
                    .textFieldStyle(.roundedBorder)
                }
                
                // 模型设置
                Section("模型设置") {
                    Picker("模型", selection: Binding(
                        get: { settingsManager.settings.selectedModel },
                        set: { settingsManager.updateModel($0) }
                    )) {
                        ForEach(settingsManager.settings.apiProvider.models, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("温度")
                            Spacer()
                            Text(String(format: "%.1f", settingsManager.settings.temperature))
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { settingsManager.settings.temperature },
                                set: { settingsManager.updateTemperature($0) }
                            ),
                            in: 0...2,
                            step: 0.1
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("最大令牌数")
                            Spacer()
                            Text("\(settingsManager.settings.maxTokens)")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { Double(settingsManager.settings.maxTokens) },
                                set: { settingsManager.updateMaxTokens(Int($0)) }
                            ),
                            in: 256...4096,
                            step: 256
                        )
                    }
                }
                
                // 系统提示词
                Section("系统提示词") {
                    TextEditor(text: Binding(
                        get: { settingsManager.settings.systemPrompt },
                        set: { settingsManager.updateSystemPrompt($0) }
                    ))
                    .frame(minHeight: 100)
                    .font(.system(.body, design: .monospaced))
                    
                    Text("设置AI助手的行为和角色")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 关于信息
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("应用名称")
                        Spacer()
                        Text("CharBox")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped) // macOS 专用表单样式
            .navigationTitle("设置")
            .toolbar {
                // macOS 适配的工具栏布局
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss() // 使用新的 dismiss 方法
                    }
                    .keyboardShortcut(.defaultAction) // 支持回车键确认
                }
            }
        }
        .frame(minWidth: 500, idealWidth: 500, maxWidth: 600,
               minHeight: 600, idealHeight: 600, maxHeight: 700)
        .padding() // macOS 添加内边距
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
}

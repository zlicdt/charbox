import Foundation
import Combine

class ChatManager: ObservableObject {
    @Published var sessions: [ChatSession] = []
    @Published var currentSession: ChatSession?
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "ChatSessions"
    
    init() {
        loadSessions()
        // 不自动选择会话，让用户主动选择
        currentSession = nil
    }
    
    // MARK: - Session Management
    
    func createNewSession() {
        let newSession = ChatSession()
        sessions.insert(newSession, at: 0)
        currentSession = newSession
        saveSessions()
    }
    
    func selectSession(_ session: ChatSession) {
        currentSession = session
    }
    
    func clearCurrentSession() {
        currentSession = nil
    }
    
    func deleteSession(_ session: ChatSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions.remove(at: index)
            
            if currentSession?.id == session.id {
                currentSession = nil
            }
            
            saveSessions()
        }
    }
    
    func renameSession(_ session: ChatSession, to newTitle: String) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index].title = newTitle
            saveSessions()
        }
    }
    
    // MARK: - Message Management
    
    func sendMessage(_ content: String, settings: ChatSettings) {
        guard var session = currentSession else { return }
        
        let userMessage = Message(content: content, isUser: true)
        session.addMessage(userMessage)
        
        DispatchQueue.main.async {
            if let index = self.sessions.firstIndex(where: { $0.id == session.id }) {
                self.sessions[index] = session
                self.currentSession = self.sessions[index]
            }
            
            self.saveSessions()
        }
        
        // 发送到API
        sendToAPIStream(settings: settings)
    }
    
    private func sendToAPIStream(settings: ChatSettings) {
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            do {
                // 创建一个空的AI消息用于流式更新
                let aiMessage = Message(content: "", isUser: false)
                await MainActor.run {
                    if var session = currentSession {
                        var streamingMessage = aiMessage
                        streamingMessage.isStreaming = true
                        session.addMessage(streamingMessage)
                        
                        if let index = self.sessions.firstIndex(where: { $0.id == session.id }) {
                            self.sessions[index] = session
                            self.currentSession = self.sessions[index]
                        }
                        self.saveSessions()
                    }
                }
                
                try await callAPIStream(settings: settings) { [weak self] chunk in
                    guard let self = self else { return }
                    Task { @MainActor in
                        if var session = self.currentSession,
                           let lastMessageIndex = session.messages.lastIndex(where: { !$0.isUser }) {
                            session.messages[lastMessageIndex].appendContent(chunk)
                            
                            if let sessionIndex = self.sessions.firstIndex(where: { $0.id == session.id }) {
                                self.sessions[sessionIndex] = session
                                self.currentSession = self.sessions[sessionIndex]
                            }
                        }
                    }
                }
                
                await MainActor.run {
                    if var session = currentSession,
                       let lastMessageIndex = session.messages.lastIndex(where: { !$0.isUser }) {
                        session.messages[lastMessageIndex].setStreaming(false)
                        
                        if let sessionIndex = sessions.firstIndex(where: { $0.id == session.id }) {
                            sessions[sessionIndex] = session
                            currentSession = sessions[sessionIndex]
                        }
                        saveSessions()
                    }
                    isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    // 错误处理
                    if var session = currentSession {
                        // 移除流式消息，添加错误消息
                        if let lastMessageIndex = session.messages.lastIndex(where: { !$0.isUser && $0.isStreaming }) {
                            session.messages.remove(at: lastMessageIndex)
                        }
                        
                        let errorMessage = Message(content: "错误: \(error.localizedDescription)", isUser: false)
                        session.addMessage(errorMessage)
                        
                        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                            sessions[index] = session
                            currentSession = sessions[index]
                        }
                        
                        saveSessions()
                    }
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - API Calls
    
    private func callAPIStream(settings: ChatSettings, onChunk: @escaping (String) -> Void) async throws {
        switch settings.apiProvider {
        case .openai:
            try await callOpenAIStream(settings: settings, onChunk: onChunk)
        case .anthropic:
            try await callAnthropicStream(settings: settings, onChunk: onChunk)
        case .gemini:
            try await callGeminiStream(settings: settings, onChunk: onChunk)
        case .ollama:
            try await callOllamaStream(settings: settings, onChunk: onChunk)
        case .siliconflow:
            try await callSiliconFlowStream(settings: settings, onChunk: onChunk)
        }
    }
    
    private func callOpenAIStream(settings: ChatSettings, onChunk: @escaping (String) -> Void) async throws {
        guard let url = URL(string: "\(settings.apiProvider.baseURL)/chat/completions") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
        
        var messages: [[String: Any]] = []
        
        if !settings.systemPrompt.isEmpty {
            messages.append([
                "role": "system",
                "content": settings.systemPrompt
            ])
        }
        
        if let session = currentSession {
            for message in session.messages {
                if !message.isStreaming { // 排除正在流式传输的消息
                    messages.append([
                        "role": message.isUser ? "user" : "assistant",
                        "content": message.content
                    ])
                }
            }
        }
        
        let body: [String: Any] = [
            "model": settings.selectedModel,
            "messages": messages,
            "temperature": settings.temperature,
            "max_tokens": settings.maxTokens,
            "stream": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (asyncBytes, _) = try await URLSession.shared.bytes(for: request)
        
        for try await line in asyncBytes.lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))
                if jsonString == "[DONE]" {
                    break
                }
                
                if let jsonData = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let delta = firstChoice["delta"] as? [String: Any],
                   let content = delta["content"] as? String {
                    onChunk(content)
                }
            }
        }
    }
    
    private func callAnthropicStream(settings: ChatSettings, onChunk: @escaping (String) -> Void) async throws {
        guard let url = URL(string: "\(settings.apiProvider.baseURL)/messages") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(settings.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        var messages: [[String: Any]] = []
        
        if let session = currentSession {
            for message in session.messages {
                if !message.isStreaming { // 排除正在流式传输的消息
                    messages.append([
                        "role": message.isUser ? "user" : "assistant",
                        "content": message.content
                    ])
                }
            }
        }
        
        let body: [String: Any] = [
            "model": settings.selectedModel,
            "messages": messages,
            "max_tokens": settings.maxTokens,
            "system": settings.systemPrompt,
            "stream": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (asyncBytes, _) = try await URLSession.shared.bytes(for: request)
        
        for try await line in asyncBytes.lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))
                if jsonString == "[DONE]" {
                    break
                }
                
                if let jsonData = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let delta = json["delta"] as? [String: Any],
                   let text = delta["text"] as? String {
                    onChunk(text)
                }
            }
        }
    }
    
    private func callGeminiStream(settings: ChatSettings, onChunk: @escaping (String) -> Void) async throws {
        // Gemini API 流式实现 (待实现)
        onChunk("Gemini API 流式响应 (待实现)")
    }
    
    private func callOllamaStream(settings: ChatSettings, onChunk: @escaping (String) -> Void) async throws {
        // Ollama API 流式实现 (待实现)
        onChunk("Ollama API 流式响应 (待实现)")
    }
    
    private func callSiliconFlowStream(settings: ChatSettings, onChunk: @escaping (String) -> Void) async throws {
        // SiliconFlow 的基础 API 地址
        let baseURL = "https://api.siliconflow.cn/v1"
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
        
        // 构建消息数组（格式与 OpenAI 相同）
        var messages: [[String: Any]] = []
        
        if !settings.systemPrompt.isEmpty {
            messages.append([
                "role": "system",
                "content": settings.systemPrompt
            ])
        }
        
        if let session = currentSession {
            for message in session.messages {
                if !message.isStreaming { // 排除正在流式传输的消息
                    messages.append([
                        "role": message.isUser ? "user" : "assistant",
                        "content": message.content
                    ])
                }
            }
        }
        
        // SiliconFlow 流式传输参数
        let body: [String: Any] = [
            "model": settings.selectedModel,
            "messages": messages,
            "temperature": settings.temperature,
            "max_tokens": settings.maxTokens,
            "stream": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
        
        // 错误响应处理
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        for try await line in asyncBytes.lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))
                if jsonString == "[DONE]" {
                    break
                }
                
                if let jsonData = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let delta = firstChoice["delta"] as? [String: Any],
                   let content = delta["content"] as? String {
                    onChunk(content)
                }
            }
        }
    }
    
    // MARK: - Persistence
    
    private func saveSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            userDefaults.set(data, forKey: sessionsKey)
        }
    }
    
    private func loadSessions() {
        if let data = userDefaults.data(forKey: sessionsKey),
           let decodedSessions = try? JSONDecoder().decode([ChatSession].self, from: data) {
            sessions = decodedSessions
        }
    }
}

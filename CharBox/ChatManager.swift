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
        if sessions.isEmpty {
            createNewSession()
        } else {
            currentSession = sessions.first
        }
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
    
    func deleteSession(_ session: ChatSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions.remove(at: index)
            
            if currentSession?.id == session.id {
                currentSession = sessions.first
            }
            
            if sessions.isEmpty {
                createNewSession()
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
        
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
            currentSession = sessions[index]
        }
        
        saveSessions()
        
        // 发送到API
        sendToAPI(settings: settings)
    }
    
    private func sendToAPI(settings: ChatSettings) {
        isLoading = true
        
        Task {
            do {
                let response = try await callAPI(settings: settings)
                await MainActor.run {
                    if var session = currentSession {
                        let aiMessage = Message(content: response, isUser: false)
                        session.addMessage(aiMessage)
                        
                        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                            sessions[index] = session
                            currentSession = sessions[index]
                        }
                        
                        saveSessions()
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    // 错误处理
                    if var session = currentSession {
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
    
    private func callAPI(settings: ChatSettings) async throws -> String {
        switch settings.apiProvider {
        case .openai:
            return try await callOpenAI(settings: settings)
        case .anthropic:
            return try await callAnthropic(settings: settings)
        case .gemini:
            return try await callGemini(settings: settings)
        case .ollama:
            return try await callOllama(settings: settings)
        case .siliconflow:
            return try await callSiliconFlow(settings: settings)
        }
    }
    
    private func callOpenAI(settings: ChatSettings) async throws -> String {
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
                messages.append([
                    "role": message.isUser ? "user" : "assistant",
                    "content": message.content
                ])
            }
        }
        
        let body: [String: Any] = [
            "model": settings.selectedModel,
            "messages": messages,
            "temperature": settings.temperature,
            "max_tokens": settings.maxTokens
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        
        throw URLError(.cannotParseResponse)
    }
    
    private func callAnthropic(settings: ChatSettings) async throws -> String {
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
                messages.append([
                    "role": message.isUser ? "user" : "assistant",
                    "content": message.content
                ])
            }
        }
        
        let body: [String: Any] = [
            "model": settings.selectedModel,
            "messages": messages,
            "max_tokens": settings.maxTokens,
            "system": settings.systemPrompt
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let content = json["content"] as? [[String: Any]],
           let firstContent = content.first,
           let text = firstContent["text"] as? String {
            return text
        }
        
        throw URLError(.cannotParseResponse)
    }
    
    private func callGemini(settings: ChatSettings) async throws -> String {
        // Gemini API 实现
        return "Gemini API 响应 (待实现)"
    }
    
    private func callOllama(settings: ChatSettings) async throws -> String {
        // Ollama API 实现
        return "Ollama API 响应 (待实现)"
    }
    private func callSiliconFlow(settings: ChatSettings) async throws -> String {
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
                messages.append([
                    "role": message.isUser ? "user" : "assistant",
                    "content": message.content
                ])
            }
        }
        
        // SiliconFlow 特有参数 (stream 和 stop 是可选项)
        let body: [String: Any] = [
            "model": settings.selectedModel,
            "messages": messages,
            "temperature": settings.temperature,
            "max_tokens": settings.maxTokens,
            "stream": false,  // 关闭流式传输
            // "stop": ["\n", "###"] // 可选: 自定义停止词
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 错误响应处理 (SiliconFlow 返回 4xx/5xx 状态码)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorResponse["message"] as? String {
                throw NSError(domain: "SiliconFlowError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            throw URLError(.badServerResponse)
        }
        
        // 解析响应内容 (结构兼容 OpenAI)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        
        return content
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

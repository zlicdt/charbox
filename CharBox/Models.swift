//
//  Models.swift
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

// MARK: - 数据模型

struct Message: Identifiable, Codable {
    var id = UUID()
    var content: String
    let isUser: Bool
    let timestamp: Date
    var isStreaming: Bool = false
    
    init(content: String, isUser: Bool) {
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.isStreaming = false
    }
    
    mutating func appendContent(_ newContent: String) {
        self.content += newContent
    }
    
    mutating func setStreaming(_ streaming: Bool) {
        self.isStreaming = streaming
    }
}

struct ChatSession: Identifiable, Codable {
    var id = UUID()
    var title: String
    var messages: [Message]
    let createdAt: Date
    var lastUpdated: Date
    
    init(title: String = "新对话") {
        self.title = title
        self.messages = []
        self.createdAt = Date()
        self.lastUpdated = Date()
    }
    
    mutating func addMessage(_ message: Message) {
        messages.append(message)
        lastUpdated = Date()
        
        // 如果是第一条用户消息，用它作为标题
        if messages.count == 1 && message.isUser {
            title = String(message.content.prefix(30))
        }
    }
}

// MARK: - API 供应商

enum APIProvider: String, CaseIterable, Codable {
    case openai = "OpenAI"
    case siliconflow = "Silicon Flow"
    case anthropic = "Anthropic"
    case gemini = "Google Gemini"
    case ollama = "Ollama"
    
    var models: [String] {
        switch self {
        case .openai:
            return ["gpt-4o", "gpt-4o-mini", "gpt-3.5-turbo", "gpt-4-turbo"]
        case .anthropic:
            return ["claude-3.5-sonnet", "claude-3-opus", "claude-3-haiku"]
        case .gemini:
            return ["gemini-pro", "gemini-pro-vision"]
        case .ollama:
            return ["llama2", "codellama", "mistral", "vicuna"]
        case .siliconflow:
            return ["deepseek-ai/DeepSeek-R1", "deepseek-ai/DeepSeek-V3"]
        }
    }
    
    var baseURL: String {
        switch self {
        case .openai:
            return "https://api.openai.com/v1"
        case .anthropic:
            return "https://api.anthropic.com/v1"
        case .gemini:
            return "https://generativelanguage.googleapis.com/v1"
        case .ollama:
            return "http://localhost:11434/v1"
        case .siliconflow:
            return "https://api.siliconflow.cn/v1"
        }
    }
}

// MARK: - 设置模型

struct ChatSettings: Codable {
    var apiProvider: APIProvider = .openai
    var selectedModel: String = "gpt-4o-mini"
    var apiKey: String = ""
    var temperature: Double = 0.7
    var systemPrompt: String = "你是一个很有帮助的AI助手。"
    var maxTokens: Int = 2048
    
    static let shared = ChatSettings()
}

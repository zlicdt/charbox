import SwiftUI
import MarkdownUI
@available(macOS 14.0, *)
struct ChatView: View {
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var inputText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            if let session = chatManager.currentSession {
                // 消息列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(session.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if chatManager.isLoading && !session.messages.contains(where: { $0.isStreaming }) {
                                LoadingMessageBubble()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: session.messages.count) {
                        guard let lastMessage = session.messages.last else { return }
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: session.messages.last?.content) { _, _ in
                        guard let lastMessage = session.messages.last else { return }
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: chatManager.isLoading) {
                        guard let lastMessage = session.messages.last else { return }
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // 输入区域
                ChatInputView(
                    inputText: $inputText,
                    isLoading: chatManager.isLoading,
                    onSend: {
                        sendMessage()
                    }
                )
            } else {
                // 空状态
                VStack(spacing: 20) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 96))
                        .foregroundColor(.blue)

                    Text("选择一个对话开始聊天")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("或者创建一个新对话")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty && !chatManager.isLoading else { return }
        
        chatManager.sendMessage(trimmedText, settings: settingsManager.settings)
        inputText = "" // Restore to empty input area
    }
}

struct MessageBubble: View {
    let message: Message
    @State private var showCopyButton = false
    @State private var showCopyConfirmation = false
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .textSelection(.enabled)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    HStack(spacing: 8) {
                        if showCopyButton {
                            Button(action: {
                                copyToClipboard(message.content)
                            }) {
                                Image(systemName: showCopyConfirmation ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity)
                        }
                        
                        Text(formatTime(message.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Markdown(message.content)
                        .textSelection(.enabled)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    HStack(spacing: 8) {
                        Text(formatTime(message.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if showCopyButton {
                            Button(action: {
                                copyToClipboard(message.content)
                            }) {
                                Image(systemName: showCopyConfirmation ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity)
                        }
                    }
                }
                
                Spacer(minLength: 50)
            }
        }
        .onHover { isHovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopyButton = isHovering
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopyConfirmation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopyConfirmation = false
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct LoadingMessageBubble: View {
    @State private var animationAmount = 0.0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(animationAmount)
                            .animation(
                                Animation.easeInOut(duration: 0.5)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: animationAmount
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            
            Spacer(minLength: 50)
        }
        .onAppear {
            animationAmount = 1.0
        }
    }
}


struct ChatInputView: View {
    @Binding var inputText: String
    let isLoading: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ScrollView {
                TextField("输入消息...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .onSubmit {
                        if !isLoading {
                            onSend()
                        }
                    }
                    .onKeyPress(.return, phases: .down) { keyPress in
                        if keyPress.modifiers.contains(.command) {
                            // Command+Enter: 插入换行符
                            inputText += "\n"
                            return .handled
                        }
                        // 对于普通的Enter键，返回.ignored让系统处理
                        // 这样可以避免与输入法冲突，让onSubmit来处理发送逻辑
                        return .ignored
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .frame(minHeight: 34, maxHeight: 100)
            .background(Color(NSColor.textBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            
            Button(action: onSend) {
                Image(systemName: isLoading ? "stop.circle" : "paperplane.fill")
                    .foregroundColor(
                        isLoading ? .red : 
                        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .accentColor
                    )
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .disabled(!isLoading && inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .frame(width: 24, height: 24)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    ChatView()
        .environmentObject(ChatManager())
        .environmentObject(SettingsManager())
}

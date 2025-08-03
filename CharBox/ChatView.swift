import SwiftUI

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
                            
                            if chatManager.isLoading {
                                LoadingMessageBubble()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: session.messages.count) { _ in
                        if let lastMessage = session.messages.last {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onChange(of: chatManager.isLoading) { _ in
                        if let lastMessage = session.messages.last {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
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
                    Image(systemName: "message")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
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
        inputText = ""
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 50)
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
        HStack(spacing: 12) {
            TextField("输入消息...", text: $inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .onSubmit {
                    if !isLoading {
                        onSend()
                    }
                }
                .disabled(isLoading)
            
            Button(action: onSend) {
                Image(systemName: isLoading ? "stop.circle" : "paperplane.fill")
                    .foregroundColor(isLoading || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .accentColor)
            }
            .buttonStyle(.plain)
            .disabled(isLoading || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

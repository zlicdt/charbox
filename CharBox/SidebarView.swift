import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var chatManager: ChatManager
    @Binding var showingSettings: Bool
    @State private var showingNewChatAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            HStack {
                Button(action: {
                    chatManager.createNewSession()
                }) {
                    Text("新对话")
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            Divider()
            
            // 对话列表
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(chatManager.sessions) { session in
                        ChatSessionRow(
                            session: session,
                            isSelected: chatManager.currentSession?.id == session.id,
                            onSelect: {
                                chatManager.selectSession(session)
                            },
                            onDelete: {
                                chatManager.deleteSession(session)
                            },
                            onRename: { newTitle in
                                chatManager.renameSession(session, to: newTitle)
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
            }
            
            Spacer()
        }
    }
}

struct ChatSessionRow: View {
    let session: ChatSession
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onRename: (String) -> Void
    
    @State private var isEditing = false
    @State private var editingTitle = ""
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if isEditing {
                    TextField("对话标题", text: $editingTitle, onCommit: {
                        onRename(editingTitle)
                        isEditing = false
                    })
                    .textFieldStyle(.roundedBorder)
                } else {
                    Text(session.title)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(formatDate(session.lastUpdated))
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            
            Spacer()
            
            if !isEditing {
                Menu {
                    Button("重命名") {
                        editingTitle = session.title
                        isEditing = true
                    }
                    
                    Button("删除", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(isSelected ? .white : .secondary)
                }
                .menuStyle(.borderlessButton)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing {
                onSelect()
            }
        }
        .alert("删除对话", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("确定要删除这个对话吗？此操作无法撤销。")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    SidebarView(showingSettings: .constant(false))
        .environmentObject(ChatManager())
        .frame(width: 280, height: 600)
}

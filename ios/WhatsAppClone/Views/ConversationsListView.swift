import SwiftUI

struct ConversationsListView: View {
    @State private var conversations: [Conversation] = []
    @State private var loading = true

    var body: some View {
        NavigationStack {
            List(conversations) { conversation in
                NavigationLink(value: conversation) {
                    HStack(spacing: 12) {
                        Circle().fill(.gray.opacity(0.3)).frame(width: 48, height: 48)
                        Text(conversation.title ?? (conversation.isGroup ? "مجموعة" : "محادثة"))
                            .font(.body)
                    }
                }
            }
            .navigationTitle("المحادثات")
            .navigationDestination(for: Conversation.self) { conversation in
                ChatView(conversation: conversation)
            }
            .task { await loadConversations() }
            .refreshable { await loadConversations() }
            .overlay {
                if loading && conversations.isEmpty {
                    ProgressView()
                } else if conversations.isEmpty {
                    Text("لا يوجد محادثات بعد").foregroundColor(.gray)
                }
            }
        }
    }

    private func loadConversations() async {
        loading = true
        defer { loading = false }
        conversations = (try? await SupabaseService.shared.fetchConversations()) ?? []
    }
}

extension Conversation: Hashable {
    static func == (lhs: Conversation, rhs: Conversation) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

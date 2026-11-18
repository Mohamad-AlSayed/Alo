import SwiftUI
import Realtime

struct ChatView: View {
    let conversation: Conversation

    @State private var messages: [Message] = []
    @State private var text = ""
    @State private var channel: RealtimeChannelV2?
    @State private var showCall: CallKind?

    enum CallKind: Identifiable { case voice, video
        var id: Self { self }
        var isVideo: Bool { self == .video }
    }

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(messages) { message in
                            bubble(for: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            HStack {
                TextField("اكتب رسالة...", text: $text)
                    .textFieldStyle(.roundedBorder)
                Button("إرسال") { Task { await send() } }
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .navigationTitle(conversation.title ?? (conversation.isGroup ? "مجموعة" : "محادثة"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { showCall = .voice } label: { Image(systemName: "phone.fill") }
                Button { showCall = .video } label: { Image(systemName: "video.fill") }
            }
        }
        .task {
            messages = (try? await SupabaseService.shared.fetchMessages(conversationId: conversation.id)) ?? []
            channel = SupabaseService.shared.subscribeToMessages(conversationId: conversation.id) { message in
                messages.append(message)
            }
        }
        .sheet(item: $showCall) { kind in
            CallView(roomName: "conv-\(conversation.id.uuidString)", isVideo: kind.isVideo)
        }
    }

    @ViewBuilder
    private func bubble(for message: Message) -> some View {
        let isMine = message.senderId == SupabaseService.shared.currentUserId
        HStack {
            if isMine { Spacer() }
            Text(message.content ?? "")
                .padding(10)
                .background(isMine ? Color.green.opacity(0.3) : Color(.systemGray5))
                .cornerRadius(10)
            if !isMine { Spacer() }
        }
    }

    private func send() async {
        let content = text
        text = ""
        try? await SupabaseService.shared.sendMessage(conversationId: conversation.id, content: content)
    }
}

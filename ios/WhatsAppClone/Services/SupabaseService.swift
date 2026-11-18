import Foundation
import Supabase

final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Secrets.supabaseURL)!,
            supabaseKey: Secrets.supabaseAnonKey
        )
    }

    var currentUserId: UUID? {
        client.auth.currentUser?.id
    }

    func sendOtp(phone: String) async throws {
        try await client.auth.signInWithOTP(phone: phone)
    }

    func verifyOtp(phone: String, code: String) async throws {
        try await client.auth.verifyOTP(phone: phone, token: code, type: .sms)
    }

    func fetchConversations() async throws -> [Conversation] {
        guard let userId = currentUserId else { return [] }
        let rows: [ConversationMemberRow] = try await client
            .from("conversation_members")
            .select("conversation:conversations(*)")
            .eq("user_id", value: userId)
            .execute()
            .value
        return rows.compactMap { $0.conversation }
    }

    func fetchMessages(conversationId: UUID) async throws -> [Message] {
        try await client
            .from("messages")
            .select()
            .eq("conversation_id", value: conversationId)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func sendMessage(conversationId: UUID, content: String) async throws {
        guard let userId = currentUserId else { return }
        try await client
            .from("messages")
            .insert([
                "conversation_id": conversationId.uuidString,
                "sender_id": userId.uuidString,
                "content": content,
            ])
            .execute()
    }

    func subscribeToMessages(
        conversationId: UUID,
        onInsert: @escaping (Message) -> Void
    ) -> RealtimeChannelV2 {
        let channel = client.realtimeV2.channel("conversation:\(conversationId.uuidString)")
        Task {
            let changes = channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "messages",
                filter: "conversation_id=eq.\(conversationId.uuidString)"
            )
            await channel.subscribe()
            for await change in changes {
                if let message: Message = try? change.decodeRecord(decoder: JSONDecoder()) {
                    onInsert(message)
                }
            }
        }
        return channel
    }

    func fetchLiveKitToken(roomName: String) async throws -> String {
        var request = URLRequest(url: URL(string: "\(Secrets.webBaseURL)/api/livekit-token")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = try? await client.auth.session.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(["roomName": roomName])
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode([String: String].self, from: data)
        guard let token = decoded["token"] else {
            throw NSError(domain: "LiveKit", code: 0, userInfo: [NSLocalizedDescriptionKey: "no token"])
        }
        return token
    }
}

private struct ConversationMemberRow: Codable {
    let conversation: Conversation?
}

enum Secrets {
    static let supabaseURL = "https://YOUR_PROJECT.supabase.co"
    static let supabaseAnonKey = "YOUR_ANON_KEY"
    static let webBaseURL = "https://YOUR_WEB_APP_DOMAIN"
    static let liveKitURL = "wss://YOUR_PROJECT.livekit.cloud"
}

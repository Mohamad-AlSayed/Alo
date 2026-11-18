import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID
    let phone: String?
    let displayName: String
    let avatarUrl: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id, phone
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case status
    }
}

struct Conversation: Codable, Identifiable {
    let id: UUID
    let isGroup: Bool
    let title: String?
    let avatarUrl: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case isGroup = "is_group"
        case title
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
    }
}

struct Message: Codable, Identifiable {
    let id: UUID
    let conversationId: UUID
    let senderId: UUID
    let content: String?
    let mediaUrl: String?
    let mediaType: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case content
        case mediaUrl = "media_url"
        case mediaType = "media_type"
        case createdAt = "created_at"
    }
}

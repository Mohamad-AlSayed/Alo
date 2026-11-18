import SwiftUI
import LiveKit
import LiveKitComponents

struct CallView: View {
    let roomName: String
    let isVideo: Bool

    @StateObject private var room = Room()
    @State private var token: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let token {
                RoomScope(room: room, url: Secrets.liveKitURL, token: token, connect: true) {
                    VideoConferenceLayout()
                        .ignoresSafeArea()
                }
            } else {
                ProgressView("جارِ الاتصال...")
            }
        }
        .task {
            token = try? await SupabaseService.shared.fetchLiveKitToken(roomName: roomName)
            try? await room.localParticipant.setMicrophone(enabled: true)
            if isVideo {
                try? await room.localParticipant.setCamera(enabled: true)
            }
        }
        .onDisappear {
            Task { await room.disconnect() }
        }
    }
}

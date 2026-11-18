import SwiftUI

@main
struct WhatsAppCloneApp: App {
    @State private var loggedIn = SupabaseService.shared.currentUserId != nil

    var body: some Scene {
        WindowGroup {
            if loggedIn {
                ConversationsListView()
            } else {
                LoginView { loggedIn = true }
            }
        }
    }
}

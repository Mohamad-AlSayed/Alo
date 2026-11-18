import SwiftUI

struct LoginView: View {
    @State private var phone = ""
    @State private var otp = ""
    @State private var stage: Stage = .phone
    @State private var error: String?
    @State private var loading = false
    var onLoggedIn: () -> Void

    enum Stage { case phone, otp }

    var body: some View {
        VStack(spacing: 16) {
            Text("تسجيل الدخول")
                .font(.title2).bold()

            if stage == .phone {
                TextField("+963xxxxxxxxx", text: $phone)
                    .keyboardType(.phonePad)
                    .textFieldStyle(.roundedBorder)

                Button(loading ? "..." : "إرسال الرمز") {
                    Task { await sendOtp() }
                }
                .disabled(loading || phone.isEmpty)
                .buttonStyle(.borderedProminent)
                .tint(.green)
            } else {
                TextField("رمز التحقق", text: $otp)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)

                Button(loading ? "..." : "تأكيد") {
                    Task { await verifyOtp() }
                }
                .disabled(loading || otp.isEmpty)
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }

            if let error {
                Text(error).foregroundColor(.red).font(.footnote)
            }
        }
        .padding(32)
    }

    private func sendOtp() async {
        loading = true; error = nil
        defer { loading = false }
        do {
            try await SupabaseService.shared.sendOtp(phone: phone)
            stage = .otp
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func verifyOtp() async {
        loading = true; error = nil
        defer { loading = false }
        do {
            try await SupabaseService.shared.verifyOtp(phone: phone, code: otp)
            onLoggedIn()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

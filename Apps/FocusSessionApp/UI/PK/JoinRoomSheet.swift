import SwiftUI

struct JoinRoomSheet: View {
    @ObservedObject var viewModel: RoomLobbyViewModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Join Room")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            Text("Enter the invite code shared by the room host.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.secondaryText)
                .multilineTextAlignment(.center)

            TextField("Invite Code", text: $viewModel.inviteCodeInput)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .textCase(.uppercase)

            HStack(spacing: 16) {
                Button("Cancel") {
                    viewModel.inviteCodeInput = ""
                    isPresented = false
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppSurfaceTheme.secondaryText)

                Button("Join") {
                    let code = viewModel.inviteCodeInput.uppercased()
                    isPresented = false
                    Task { await viewModel.joinRoom(inviteCode: code) }
                }
                .disabled(viewModel.inviteCodeInput.trimmingCharacters(in: .whitespaces).isEmpty)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .buttonStyle(.plain)
                .foregroundStyle(AppSurfaceTheme.primaryText)
            }
        }
        .padding(32)
        .frame(width: 320)
        .background(AppCanvasBackground())
    }
}

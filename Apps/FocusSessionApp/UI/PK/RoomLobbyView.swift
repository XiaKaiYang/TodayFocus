import SwiftUI

struct RoomLobbyView: View {
    @ObservedObject var viewModel: RoomLobbyViewModel
    @State private var showJoinSheet = false
    @State private var showCreateSheet = false
    @State private var newRoomTitle = ""
    @State private var newRoomMinutes = 25

    var body: some View {
        ZStack {
            AppCanvasBackground()
            if viewModel.isLoading {
                ProgressView("Loading…")
                    .foregroundStyle(AppSurfaceTheme.primaryText)
            } else if let room = viewModel.currentRoom {
                roomContent(room)
            } else {
                noRoomContent
            }
        }
        .sheet(isPresented: $showJoinSheet) {
            JoinRoomSheet(viewModel: viewModel, isPresented: $showJoinSheet)
        }
        .sheet(isPresented: $showCreateSheet) {
            createRoomSheet
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var noRoomContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(AppSurfaceTheme.secondaryText)

            Text("PK Room")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            Text("Create a room to host a supervised focus session, or join one with an invite code.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)

            HStack(spacing: 16) {
                Button("Create Room") {
                    showCreateSheet = true
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.2))
                )
                .foregroundStyle(AppSurfaceTheme.primaryText)
                .buttonStyle(.plain)

                Button("Join Room") {
                    showJoinSheet = true
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                )
                .foregroundStyle(AppSurfaceTheme.primaryText)
                .buttonStyle(.plain)
            }
        }
        .padding(40)
    }

    private func roomContent(_ room: RoomRecord) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.primaryText)
                    Text("\(room.plannedMinutes) min · \(room.status.rawValue.capitalized)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.secondaryText)
                }
                Spacer()
                if let code = viewModel.inviteCode {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Invite Code")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.secondaryText)
                        Text(code)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.primaryText)
                    }
                }
            }

            Divider().opacity(0.3)

            Text("Members (\(viewModel.members.count))")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.secondaryText)

            ForEach(viewModel.members, id: \.userID) { member in
                HStack {
                    Image(systemName: member.role == .owner ? "crown.fill" : "person.fill")
                        .foregroundStyle(AppSurfaceTheme.secondaryText)
                        .frame(width: 20)
                    Text(member.userID)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.primaryText)
                    Spacer()
                    Text(member.readyState == .ready ? "Ready" : "Not Ready")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(member.readyState == .ready ? .green : AppSurfaceTheme.secondaryText)
                }
                .padding(.vertical, 6)
            }

            Spacer()

            HStack(spacing: 12) {
                if viewModel.currentMembership?.role != .owner {
                    let isReady = viewModel.currentMembership?.readyState == .ready
                    Toggle("Ready", isOn: Binding(
                        get: { isReady },
                        set: { newValue in Task { await viewModel.setReady(newValue) } }
                    ))
                    .toggleStyle(.switch)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                }

                if viewModel.currentMembership?.role == .owner {
                    Button("Start Session") {
                        Task { await viewModel.startSession() }
                    }
                    .disabled(!viewModel.canStartSession)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(viewModel.canStartSession ? Color.green.opacity(0.3) : Color.white.opacity(0.1))
                    )
                    .foregroundStyle(AppSurfaceTheme.primaryText)
                    .buttonStyle(.plain)
                }

                Spacer()

                Button("Leave") {
                    Task { await viewModel.leaveRoom() }
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.secondaryText)
                .buttonStyle(.plain)
            }
        }
        .padding(24)
    }

    private var createRoomSheet: some View {
        VStack(spacing: 20) {
            Text("Create Room")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            TextField("Room Title", text: $newRoomTitle)
                .textFieldStyle(.roundedBorder)

            Stepper("Duration: \(newRoomMinutes) min", value: $newRoomMinutes, in: 5...120, step: 5)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            HStack(spacing: 12) {
                Button("Cancel") { showCreateSheet = false }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppSurfaceTheme.secondaryText)

                Button("Create") {
                    showCreateSheet = false
                    Task { await viewModel.createRoom(title: newRoomTitle, plannedMinutes: newRoomMinutes) }
                }
                .disabled(newRoomTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .buttonStyle(.plain)
                .foregroundStyle(AppSurfaceTheme.primaryText)
            }
        }
        .padding(32)
        .frame(width: 340)
        .background(AppCanvasBackground())
    }
}

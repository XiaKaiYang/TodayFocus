import AuthenticationServices
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

            if viewModel.currentRoom == nil {
                hallBackdrop
            }

            if viewModel.isLoading {
                ProgressView("Loading…")
                    .foregroundStyle(AppSurfaceTheme.primaryText)
            } else if let room = viewModel.currentRoom {
                roomContent(room)
            } else {
                tableHallContent
            }
        }
        .task {
            await viewModel.loadTableHall()
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

    private var hallBackdrop: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.94, blue: 0.89).opacity(0.66),
                    Color(red: 0.93, green: 0.88, blue: 0.80).opacity(0.52)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color(red: 0.99, green: 0.92, blue: 0.74).opacity(0.36),
                    .clear
                ],
                center: .top,
                startRadius: 16,
                endRadius: 620
            )

            VStack(spacing: 120) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 110) {
                        ForEach(0..<5, id: \.self) { column in
                            Circle()
                                .fill(Color(red: 0.87, green: 0.78, blue: 0.61).opacity((row + column).isMultiple(of: 2) ? 0.10 : 0.05))
                                .frame(width: 10, height: 10)
                                .blur(radius: 1.2)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var tableHallContent: some View {
        VStack(alignment: .leading, spacing: 26) {
            VStack(alignment: .leading, spacing: 10) {
                Text("PK Tables")
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.primaryText)

                Text("Pick a small table, sit down, or join by invite code.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.secondaryText)

                if viewModel.isSignedIn == false {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sign in to create or join a PK room.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.secondaryText)

                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { _ in
                            viewModel.signIn()
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(width: 240, height: 44)
                    }
                } else if let accountDisplayName = viewModel.accountDisplayName {
                    Text(AppText.format("Signed in as %@", accountDisplayName))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.secondaryText)
                }
            }

            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 260), spacing: 26, alignment: .top)
                    ],
                    spacing: 26
                ) {
                    ForEach(viewModel.tables) { table in
                        Button {
                            Task { await viewModel.selectTable(table) }
                        } label: {
                            arcadeTableCard(table)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isSignedIn == false)
                    }
                }
                .padding(.top, 6)
            }

            HStack(spacing: 14) {
                hallActionButton(
                    title: "Create Table",
                    tint: AppSurfaceTheme.accentGradient,
                    isDisabled: viewModel.isSignedIn == false
                ) {
                    showCreateSheet = true
                }

                hallActionButton(
                    title: "Join by Code",
                    tint: nil,
                    isDisabled: viewModel.isSignedIn == false
                ) {
                    showJoinSheet = true
                }

                hallActionButton(
                    title: "Refresh",
                    tint: nil,
                    isDisabled: false
                ) {
                    Task { await viewModel.loadTableHall() }
                }
            }
        }
        .padding(28)
    }

    private func roomContent(_ room: RoomRecord) -> some View {
        VStack(spacing: 24) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(room.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.primaryText)
                    Text(AppText.format("%d min table · %@", room.plannedMinutes, localizedRoomStatusText(room.status)))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.secondaryText)
                }
                Spacer()
                if let code = viewModel.inviteCode {
                    inviteCard(code: code)
                }
            }

            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 44, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.96, blue: 0.93).opacity(0.99),
                                    Color(red: 0.93, green: 0.89, blue: 0.84).opacity(0.99)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 44, style: .continuous)
                                .stroke(Color.white.opacity(0.55), lineWidth: 1)
                        )
                        .shadow(color: Color(red: 0.45, green: 0.34, blue: 0.23).opacity(0.10), radius: 18, y: 10)

                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(Color(red: 0.82, green: 0.72, blue: 0.60).opacity(0.80), lineWidth: 2)
                        .padding(18)

                    ForEach(0..<4, id: \.self) { slot in
                        roomSeatBubble(member: roomSeatMember(at: slot), slot: slot, in: geometry.size)
                    }

                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.83, green: 0.69, blue: 0.53),
                                    Color(red: 0.72, green: 0.57, blue: 0.41)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: min(geometry.size.width * 0.56, 430), height: min(geometry.size.height * 0.52, 300))
                        .shadow(color: Color(red: 0.41, green: 0.30, blue: 0.18).opacity(0.16), radius: 18, y: 12)

                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.92, green: 0.91, blue: 0.84),
                                    Color(red: 0.83, green: 0.87, blue: 0.79)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: min(geometry.size.width * 0.49, 374), height: min(geometry.size.height * 0.44, 248))
                        .overlay(
                            Ellipse()
                                .stroke(Color.white.opacity(0.35), lineWidth: 2)
                        )

                    centerDeskContent(room: room)
                }
            }
            .frame(maxWidth: 820, minHeight: 500)

            HStack {
                if viewModel.currentMembership?.role != .owner {
                    let isReady = viewModel.currentMembership?.readyState == .ready
                    Toggle("Ready", isOn: Binding(
                        get: { isReady },
                        set: { newValue in Task { await viewModel.setReady(newValue) } }
                    ))
                    .toggleStyle(.switch)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                }

                Spacer()

                Button("Leave") {
                    Task { await viewModel.leaveRoom() }
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.12))
                )
                .buttonStyle(.plain)
            }
        }
        .padding(28)
    }

    private func arcadeTableCard(_ table: PKTableSummary) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.96, blue: 0.93).opacity(0.98),
                            Color(red: 0.94, green: 0.90, blue: 0.84).opacity(0.99)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color.white.opacity(0.62), lineWidth: 1)
                )

            GeometryReader { geometry in
                let tableWidth = geometry.size.width * 0.66
                let tableHeight = geometry.size.height * 0.46

                ZStack {
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.95, blue: 0.82).opacity(0.34),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 150
                            )
                        )
                        .frame(width: tableWidth * 1.2, height: tableHeight * 1.2)

                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.84, green: 0.70, blue: 0.54),
                                    Color(red: 0.74, green: 0.59, blue: 0.43)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: tableWidth, height: tableHeight)

                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: feltColors(for: table),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: tableWidth * 0.86, height: tableHeight * 0.80)
                        .overlay(
                            Ellipse()
                                .stroke(Color.white.opacity(0.08), lineWidth: 2)
                        )

                    ForEach(0..<4, id: \.self) { slot in
                        chairBubble(
                            occupied: slot < table.memberCount,
                            slot: slot,
                            in: geometry.size
                        )
                    }

                    VStack(spacing: 6) {
                        Text(table.status == .running ? "进行中" : "等待中")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.26, green: 0.20, blue: 0.13))

                        Text(AppText.format("%d min", table.plannedMinutes))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(red: 0.40, green: 0.30, blue: 0.20).opacity(0.82))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.70))
                    )
                }
            }

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    if table.isCurrentUsersTable {
                        Text("继续")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color(red: 0.84, green: 0.58, blue: 0.44))
                            )
                            .foregroundStyle(Color(red: 0.35, green: 0.19, blue: 0.09))
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        sourceBadge(table.source)
                        statusBadge(table.status)
                    }
                }

                Spacer()

                tableNumberPlate(table)
            }
            .padding(18)
        }
        .frame(height: 238)
        .shadow(color: Color.black.opacity(0.16), radius: 22, y: 14)
    }

    private func feltColors(for table: PKTableSummary) -> [Color] {
        switch table.status {
        case .open:
            return [
                Color(red: 0.89, green: 0.89, blue: 0.82),
                Color(red: 0.79, green: 0.84, blue: 0.76)
            ]
        case .running:
            return [
                Color(red: 0.88, green: 0.86, blue: 0.78),
                Color(red: 0.77, green: 0.81, blue: 0.72)
            ]
        case .full:
            return [
                Color(red: 0.82, green: 0.79, blue: 0.74),
                Color(red: 0.71, green: 0.67, blue: 0.62)
            ]
        }
    }

    private func chairBubble(
        occupied: Bool,
        slot: Int,
        in size: CGSize
    ) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(occupied ? Color(red: 0.97, green: 0.94, blue: 0.88) : Color.white.opacity(0.40))
            .frame(width: 44, height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .overlay {
                if occupied {
                    Image(systemName: "person.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(red: 0.39, green: 0.27, blue: 0.16))
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.42))
                        .frame(width: 10, height: 10)
                }
            }
            .position(chairPosition(slot: slot, in: size, orbitX: size.width * 0.27, orbitY: size.height * 0.18))
    }

    private func chairPosition(
        slot: Int,
        in size: CGSize,
        orbitX: CGFloat,
        orbitY: CGFloat
    ) -> CGPoint {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        switch slot {
        case 0:
            return CGPoint(x: center.x, y: center.y - orbitY)
        case 1:
            return CGPoint(x: center.x + orbitX, y: center.y)
        case 2:
            return CGPoint(x: center.x, y: center.y + orbitY)
        default:
            return CGPoint(x: center.x - orbitX, y: center.y)
        }
    }

    private func tableNumberPlate(_ table: PKTableSummary) -> some View {
        HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(table.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.33, green: 0.22, blue: 0.13))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text(AppText.format("Code %@", table.inviteCode))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.48, green: 0.33, blue: 0.22).opacity(0.82))
                }

            Spacer()

            Text("\(table.memberCount)/\(table.capacity)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.38, green: 0.23, blue: 0.10))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.42))
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.96, green: 0.88, blue: 0.72),
                            Color(red: 0.89, green: 0.76, blue: 0.58)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.30), lineWidth: 1)
        )
    }

    private func sourceBadge(_ source: PKTableSource) -> some View {
        Text(source == .live ? "实时" : "本地")
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(red: 0.88, green: 0.82, blue: 0.74).opacity(0.96))
            )
            .foregroundStyle(Color(red: 0.39, green: 0.27, blue: 0.16))
    }

    private func statusBadge(_ status: PKTableStatus) -> some View {
        Text(localizedTableStatusText(status))
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(statusFillColor(for: status))
            )
            .foregroundStyle(Color(red: 0.30, green: 0.20, blue: 0.12))
    }

    private func statusFillColor(for status: PKTableStatus) -> Color {
        switch status {
        case .open:
            return Color(red: 0.56, green: 0.69, blue: 0.58)
        case .running:
            return Color(red: 0.84, green: 0.64, blue: 0.46)
        case .full:
            return Color(red: 0.73, green: 0.68, blue: 0.63)
        }
    }

    private func hallActionButton(
        title: String,
        tint: LinearGradient?,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .disabled(isDisabled)
        .font(.system(size: 15, weight: .semibold, design: .rounded))
        .foregroundStyle(tint == nil ? AppSurfaceTheme.primaryText : AppSurfaceTheme.accentText)
        .background(
            Group {
                if let tint {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(tint)
                } else {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(isDisabled ? 0.08 : 0.18))
                }
            }
        )
        .opacity(isDisabled ? 0.55 : 1)
        .buttonStyle(.plain)
    }

    private func inviteCard(code: String) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("邀请码")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.42, green: 0.30, blue: 0.18).opacity(0.82))
            Text(code)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.35, green: 0.24, blue: 0.14))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.93, blue: 0.83),
                            Color(red: 0.92, green: 0.82, blue: 0.68)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.26), lineWidth: 1)
        )
    }

    private func centerDeskContent(room: RoomRecord) -> some View {
        VStack(spacing: 10) {
            if room.status == .running {
                Text(viewModel.centerTimerText)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.26, green: 0.18, blue: 0.11))
                Text(viewModel.centerStatusText)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.31, green: 0.24, blue: 0.16).opacity(0.82))
            } else {
                Text("准备桌")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.26, green: 0.18, blue: 0.11))
                Text("成员已就座。可以从桌面中央开始本轮专注。")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.33, green: 0.25, blue: 0.17).opacity(0.82))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)

                if viewModel.currentMembership?.role == .owner {
                    Button("开始专注") {
                        Task { await viewModel.startSession() }
                    }
                    .disabled(!viewModel.canStartSession)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                viewModel.canStartSession
                                    ? LinearGradient(
                                        colors: [
                                            Color(red: 0.98, green: 0.77, blue: 0.33),
                                            Color(red: 0.88, green: 0.55, blue: 0.20)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.white.opacity(0.14), Color.white.opacity(0.10)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                    )
                    .foregroundStyle(viewModel.canStartSession ? Color(red: 0.31, green: 0.18, blue: 0.07) : Color(red: 0.40, green: 0.31, blue: 0.20).opacity(0.72))
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
    }

    private func roomSeatMember(at index: Int) -> RoomMemberRecord? {
        let sortedMembers = viewModel.members.sorted { lhs, rhs in
            if lhs.role != rhs.role {
                return lhs.role == .owner
            }
            return lhs.userID.localizedCaseInsensitiveCompare(rhs.userID) == .orderedAscending
        }

        guard index < sortedMembers.count else {
            return nil
        }

        return sortedMembers[index]
    }

    private func roomSeatBubble(
        member: RoomMemberRecord?,
        slot: Int,
        in size: CGSize
    ) -> some View {
        VStack(spacing: 8) {
            if let member {
                HStack(spacing: 6) {
                    Image(systemName: member.role == .owner ? "crown.fill" : "person.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text(member.userID)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .lineLimit(1)
                }
                .foregroundStyle(Color(red: 0.25, green: 0.17, blue: 0.09))

                HStack(spacing: 6) {
                    Circle()
                        .fill(seatStatusColor(for: member))
                        .frame(width: 10, height: 10)
                    Text(seatStatusLabel(for: member))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.42, green: 0.30, blue: 0.18))
                }
            } else {
                Text("空位")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.45, green: 0.34, blue: 0.23).opacity(0.82))
                Text("开放")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.54, green: 0.42, blue: 0.30).opacity(0.72))
            }
        }
        .frame(width: 148, height: 88)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(member == nil ? Color(red: 0.97, green: 0.95, blue: 0.91) : Color(red: 0.98, green: 0.95, blue: 0.89))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(member == nil ? Color(red: 0.84, green: 0.78, blue: 0.70).opacity(0.44) : Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(member == nil ? 0.08 : 0.12), radius: 12, y: 8)
        .position(chairPosition(slot: slot, in: size, orbitX: min(size.width * 0.37, 290), orbitY: min(size.height * 0.30, 170)))
    }

    private func seatStatusLabel(for member: RoomMemberRecord) -> String {
        if member.readyState == .ready && viewModel.currentRoom?.status == .lobby {
            return "准备完成"
        }

        switch member.currentSeatState {
        case .present:
            switch member.currentActivityState {
            case .active:
                return "在座"
            case .inactive:
                return "无活动"
            case .unknown:
                return "在座"
            }
        case .away:
            return "离开"
        case .unknown:
            return "等待中"
        }
    }

    private func seatStatusColor(for member: RoomMemberRecord) -> Color {
        if member.readyState == .ready && viewModel.currentRoom?.status == .lobby {
            return Color(red: 0.31, green: 0.69, blue: 0.41)
        }

        switch member.currentSeatState {
        case .present:
            switch member.currentActivityState {
            case .inactive:
                return Color(red: 0.60, green: 0.53, blue: 0.50)
            case .active, .unknown:
                return Color(red: 0.31, green: 0.69, blue: 0.41)
            }
        case .away:
            return Color(red: 0.86, green: 0.57, blue: 0.24)
        case .unknown:
            return Color(red: 0.67, green: 0.58, blue: 0.48)
        }
    }

    private func localizedTableStatusText(_ status: PKTableStatus) -> String {
        switch status {
        case .open:
            return "开放"
        case .running:
            return "进行中"
        case .full:
            return "已满"
        }
    }

    private func localizedRoomStatusText(_ status: RoomStatus) -> String {
        switch status {
        case .lobby:
            return "等待中"
        case .running:
            return "进行中"
        case .ended:
            return "已结束"
        case .cancelled:
            return "已取消"
        }
    }

    private func statusBadge(_ status: RoomStatus) -> some View {
        Text(localizedRoomStatusText(status))
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(statusFillColor(for: status))
            )
            .foregroundStyle(Color(red: 0.30, green: 0.20, blue: 0.12))
    }

    private func statusFillColor(for status: RoomStatus) -> Color {
        switch status {
        case .lobby:
            return Color(red: 0.56, green: 0.69, blue: 0.58)
        case .running:
            return Color(red: 0.84, green: 0.64, blue: 0.46)
        case .ended:
            return Color(red: 0.73, green: 0.68, blue: 0.63)
        case .cancelled:
            return Color(red: 0.60, green: 0.53, blue: 0.50)
        }
    }

    private var createRoomSheet: some View {
        VStack(spacing: 20) {
            Text("创建房间")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            TextField("房间标题", text: $newRoomTitle)
                .textFieldStyle(.roundedBorder)

            Stepper("时长：\(newRoomMinutes) 分钟", value: $newRoomMinutes, in: 5...120, step: 5)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            HStack(spacing: 12) {
                Button("Cancel") { showCreateSheet = false }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppSurfaceTheme.secondaryText)

                Button("创建") {
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

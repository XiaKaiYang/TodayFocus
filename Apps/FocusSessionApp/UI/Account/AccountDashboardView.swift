import AuthenticationServices
import SwiftUI

struct AccountDashboardView: View {
    @ObservedObject var viewModel: AccountViewModel
    @State private var bioDraft = ""
    @State private var isSavingBio = false
    @State private var bioMessage: String?

    var body: some View {
        ZStack {
            AppCanvasBackground()
            contentView
        }
        .onAppear {
            syncBioDraft()
        }
        .onChange(of: viewModel.currentProfile?.bio) { _, _ in
            syncBioDraft()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .signedOut:
            signedOutView

        case .signingIn:
            ProgressView("正在登录…")
                .foregroundStyle(AppSurfaceTheme.primaryText)

        case .profileLoading(let identity):
            ProgressView("正在加载 \(identity.displayName) 的资料…")
                .foregroundStyle(AppSurfaceTheme.primaryText)

        case .ready(_, let profile):
            profileCard(profile)

        case .error(let message):
            errorView(message)
        }
    }

    private var signedOutView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(AppSurfaceTheme.secondaryText)

            Text("个人主页")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            Text("登录后可以查看专注对战战绩，编辑个人简介，并管理账户状态。")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.secondaryText)
                .multilineTextAlignment(.center)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { _ in
                viewModel.signIn()
            }
            .signInWithAppleButtonStyle(.white)
            .frame(width: 220, height: 44)
        }
        .padding(40)
    }

    private func profileCard(_ profile: UserPublicProfileRecord) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .center, spacing: 18) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 64, weight: .medium))
                        .foregroundStyle(AppSurfaceTheme.secondaryText)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(profile.displayName)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.primaryText)

                        Text("TodayFocus 账户")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.secondaryText)
                    }

                    Spacer()

                    Button("退出登录") {
                        viewModel.signOut()
                    }
                    .buttonStyle(AppGlassButtonStyle())
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("个人简介")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.primaryText)

                    AppPromptedTextEditor(
                        prompt: "介绍一下你现在的目标、习惯或者想坚持的事情。",
                        text: $bioDraft,
                        fontSize: 16,
                        cornerRadius: 24,
                        horizontalInset: 16,
                        verticalInset: 14
                    )
                    .frame(minHeight: 140)

                    HStack {
                        if let bioMessage {
                            Text(bioMessage)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppSurfaceTheme.secondaryText)
                        }

                        Spacer()

                        Button(isSavingBio ? "保存中…" : "保存简介") {
                            Task { await saveBio() }
                        }
                        .buttonStyle(AppAccentButtonStyle())
                        .disabled(isSavingBio)
                    }
                }
                .padding(24)
                .background(AppCardSurface(style: .standard, cornerRadius: 28))

                VStack(alignment: .leading, spacing: 16) {
                    Text("专注对战战绩")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.primaryText)

                    HStack(spacing: 16) {
                        statItem(value: "\(profile.totalVerifiedMinutes)", label: "有效专注分钟")
                        statItem(value: "\(profile.totalWins)", label: "胜场")
                        statItem(value: "\(profile.totalPenaltyCount)", label: "违规次数")
                    }
                }
                .padding(24)
                .background(AppCardSurface(style: .standard, cornerRadius: 28))
            }
            .padding(32)
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(.orange)

            Text("个人页加载失败")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.secondaryText)
                .multilineTextAlignment(.center)

            Button("重新登录") {
                viewModel.signIn()
            }
            .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .padding(40)
    }

    private func syncBioDraft() {
        guard !isSavingBio else { return }
        bioDraft = viewModel.currentProfile?.bio ?? ""
    }

    private func saveBio() async {
        isSavingBio = true
        defer { isSavingBio = false }

        do {
            try await viewModel.updateBio(bioDraft)
            bioMessage = "个人简介已保存"
        } catch {
            bioMessage = error.localizedDescription
        }
    }
}

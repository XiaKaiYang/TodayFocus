import AuthenticationServices
import SwiftUI

struct AccountDashboardView: View {
    @ObservedObject var viewModel: AccountViewModel

    var body: some View {
        ZStack {
            AppCanvasBackground()
            contentView
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .signedOut:
            signedOutView

        case .signingIn:
            ProgressView("Signing in…")
                .foregroundStyle(AppSurfaceTheme.primaryText)

        case .profileLoading(let identity):
            ProgressView(AppText.format("Loading profile for %@…", identity.displayName))
                .foregroundStyle(AppSurfaceTheme.primaryText)

        case .ready(_, let profile):
            profileCard(profile)

        case .error(let message):
            errorView(message)
        }
    }

    private var signedOutView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(AppSurfaceTheme.secondaryText)

            Text("PK Room")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            Text("Sign in to compete in supervised focus rooms.")
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
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(AppSurfaceTheme.secondaryText)

            Text(profile.displayName)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            HStack(spacing: 32) {
                statItem(value: "\(profile.totalVerifiedMinutes)", label: AppText.tr("Verified Min"))
                statItem(value: "\(profile.totalWins)", label: AppText.tr("Wins"))
                statItem(value: "\(profile.totalPenaltyCount)", label: AppText.tr("Penalties"))
            }

            Button("Sign Out") {
                viewModel.signOut()
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(AppSurfaceTheme.secondaryText)
        }
        .padding(40)
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
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(.orange)

            Text("Something went wrong")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.secondaryText)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                viewModel.signIn()
            }
            .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .padding(40)
    }
}

import Foundation

enum AccountState: Equatable {
    case signedOut
    case signingIn
    case profileLoading(AccountIdentity)
    case ready(AccountIdentity, UserPublicProfileRecord)
    case error(String)
}

@MainActor
final class AccountViewModel: ObservableObject {
    @Published private(set) var state: AccountState = .signedOut

    private let accountService: any AccountServicing
    private let profileRepository: any UserPublicProfileRepositoryProtocol
    private let cloudProfileSyncAvailabilityProvider: @Sendable () -> Bool

    init(
        accountService: any AccountServicing = AccountService(),
        profileRepository: any UserPublicProfileRepositoryProtocol = UserPublicProfileRepository(),
        cloudProfileSyncAvailabilityProvider: @escaping @Sendable () -> Bool = CloudKitDatabaseProvider.isAvailable
    ) {
        self.accountService = accountService
        self.profileRepository = profileRepository
        self.cloudProfileSyncAvailabilityProvider = cloudProfileSyncAvailabilityProvider
    }

    func restoreSession() async {
        do {
            guard let identity = try await accountService.restoreSession() else {
                state = .signedOut
                return
            }
            await loadProfile(for: identity)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func signIn() {
        Task {
            state = .signingIn
            do {
                let identity = try await accountService.signIn()
                await loadProfile(for: identity)
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    func signOut() {
        accountService.signOut()
        state = .signedOut
    }

    func updateBio(_ bio: String) async throws {
        guard case let .ready(identity, profile) = state else {
            throw AccountProfileUpdateError.notReady
        }

        let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        var updatedProfile = profile
        updatedProfile.bio = trimmedBio

        if cloudProfileSyncAvailabilityProvider() {
            try await profileRepository.upsert(updatedProfile)
        }

        state = .ready(identity, updatedProfile)
    }

    var currentUserID: String? {
        switch state {
        case .ready(let identity, _):
            return identity.userID
        case .profileLoading(let identity):
            return identity.userID
        default:
            return accountService.currentIdentity?.userID
        }
    }

    var isSignedIn: Bool {
        switch state {
        case .ready, .profileLoading:
            return true
        case .signedOut, .signingIn, .error:
            return false
        }
    }

    var displayName: String? {
        switch state {
        case .ready(let identity, _):
            return identity.displayName
        case .profileLoading(let identity):
            return identity.displayName
        default:
            return nil
        }
    }

    var currentProfile: UserPublicProfileRecord? {
        if case .ready(_, let profile) = state {
            return profile
        }
        return nil
    }

    private func loadProfile(for identity: AccountIdentity) async {
        guard cloudProfileSyncAvailabilityProvider() else {
            state = .ready(
                identity,
                UserPublicProfileRecord(userID: identity.userID, displayName: identity.displayName)
            )
            return
        }

        state = .profileLoading(identity)
        do {
            if let existing = try await profileRepository.fetch(userID: identity.userID) {
                state = .ready(identity, existing)
            } else {
                let newProfile = UserPublicProfileRecord(userID: identity.userID, displayName: identity.displayName)
                try await profileRepository.upsert(newProfile)
                state = .ready(identity, newProfile)
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

enum AccountProfileUpdateError: LocalizedError {
    case notReady

    var errorDescription: String? {
        switch self {
        case .notReady:
            return "账户资料尚未准备好。"
        }
    }
}

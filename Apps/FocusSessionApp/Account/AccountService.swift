import AuthenticationServices
import CryptoKit
import Foundation

@MainActor
protocol AccountServicing: AnyObject, Sendable {
    var currentIdentity: AccountIdentity? { get }
    func restoreSession() async throws -> AccountIdentity?
    func signIn() async throws -> AccountIdentity
    func signOut()
}

@MainActor
final class AccountService: AccountServicing {
    private static let userIDKey = "AccountService.userID"
    private static let displayNameKey = "AccountService.displayName"

    private(set) var currentIdentity: AccountIdentity?

    init() {
        currentIdentity = loadFromDefaults()
    }

    func restoreSession() async throws -> AccountIdentity? {
        let identity = loadFromDefaults()
        currentIdentity = identity
        return identity
    }

    func signIn() async throws -> AccountIdentity {
        return try await withCheckedThrowingContinuation { continuation in
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let nonce = UUID().uuidString
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleSignInDelegate(nonce: nonce, continuation: continuation) { [weak self] identity in
                self?.persistIdentity(identity)
                self?.currentIdentity = identity
            }
            controller.delegate = delegate
            controller.performRequests()
            // Keep delegate alive for the duration of the request
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    func signOut() {
        currentIdentity = nil
        UserDefaults.standard.removeObject(forKey: Self.userIDKey)
        UserDefaults.standard.removeObject(forKey: Self.displayNameKey)
    }

    private func loadFromDefaults() -> AccountIdentity? {
        guard
            let userID = UserDefaults.standard.string(forKey: Self.userIDKey),
            let displayName = UserDefaults.standard.string(forKey: Self.displayNameKey)
        else { return nil }
        return AccountIdentity(userID: userID, displayName: displayName, email: nil)
    }

    private func persistIdentity(_ identity: AccountIdentity) {
        UserDefaults.standard.set(identity.userID, forKey: Self.userIDKey)
        UserDefaults.standard.set(identity.displayName, forKey: Self.displayNameKey)
    }
}

private final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, @unchecked Sendable {
    private let nonce: String
    private let continuation: CheckedContinuation<AccountIdentity, Error>
    private let onSuccess: (AccountIdentity) -> Void

    init(
        nonce: String,
        continuation: CheckedContinuation<AccountIdentity, Error>,
        onSuccess: @escaping (AccountIdentity) -> Void
    ) {
        self.nonce = nonce
        self.continuation = continuation
        self.onSuccess = onSuccess
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation.resume(throwing: AccountServiceError.invalidCredential)
            return
        }
        let rawUserID = credential.user
        let hashedUserID = SHA256.hash(data: Data(rawUserID.utf8))
            .compactMap { String(format: "%02x", $0) }.joined()

        let displayName: String
        if let fullName = credential.fullName {
            let parts = [fullName.givenName, fullName.familyName].compactMap { $0 }
            displayName = parts.joined(separator: " ")
        } else {
            displayName = "User"
        }

        let identity = AccountIdentity(
            userID: hashedUserID,
            displayName: displayName.isEmpty ? "User" : displayName,
            email: credential.email
        )
        onSuccess(identity)
        continuation.resume(returning: identity)
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        continuation.resume(throwing: error)
    }
}

enum AccountServiceError: Error, LocalizedError {
    case invalidCredential
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Invalid Apple ID credential."
        case .notAvailable: return "Sign In with Apple is not available."
        }
    }
}

@MainActor
final class StubAccountService: AccountServicing {
    var stubbedIdentity: AccountIdentity?

    var currentIdentity: AccountIdentity? { stubbedIdentity }

    func restoreSession() async throws -> AccountIdentity? {
        return stubbedIdentity
    }

    func signIn() async throws -> AccountIdentity {
        guard let identity = stubbedIdentity else {
            throw AccountServiceError.notAvailable
        }
        return identity
    }

    func signOut() {
        stubbedIdentity = nil
    }
}

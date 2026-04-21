import Foundation

struct AccountIdentity: Equatable, Sendable {
    let userID: String
    let displayName: String
    let email: String?
}

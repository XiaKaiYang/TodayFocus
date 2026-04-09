import Foundation

public enum FocusSessionDeepLinkDestination: String, Equatable {
    case plan
}

public enum FocusSessionDeepLink {
    public static let scheme = "todayfocus"
    public static let planURL = URL(string: "\(scheme)://plan")!

    public static func destination(for url: URL) -> FocusSessionDeepLinkDestination? {
        guard url.scheme?.lowercased() == scheme else {
            return nil
        }

        let candidate = url.host?.lowercased()
            ?? url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()

        switch candidate {
        case FocusSessionDeepLinkDestination.plan.rawValue:
            return FocusSessionDeepLinkDestination.plan
        default:
            return nil
        }
    }
}

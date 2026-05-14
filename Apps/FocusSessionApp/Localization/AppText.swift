import Foundation

enum AppText {
    private static let localizationBundle: Bundle = {
        if let path = Bundle.main.path(forResource: "zh-Hans", ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }

        return .main
    }()

    static func tr(_ key: String) -> String {
        localizationBundle.localizedString(forKey: key, value: key, table: "Localizable")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(
            format: tr(key),
            locale: .autoupdatingCurrent,
            arguments: arguments
        )
    }
}

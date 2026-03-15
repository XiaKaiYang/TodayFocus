import XCTest

final class MobileSupportSourceTests: XCTestCase {
    func testProjectAddsDedicatedIOSAppAndTestTargets() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let projectFileURL = root.appendingPathComponent("project.yml")
        let contents = try String(contentsOf: projectFileURL, encoding: .utf8)

        XCTAssertTrue(contents.contains("FocusSessionMobileApp:"))
        XCTAssertTrue(contents.contains("platform: iOS"))
        XCTAssertTrue(contents.contains("FocusSessionMobileAppTests:"))
        XCTAssertTrue(contents.contains("Config/Entitlements/FocusSessionMobileApp.entitlements"))
    }

    func testIOSProjectExcludesInfoPlistsFromSources() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let projectFileURL = root.appendingPathComponent("project.yml")
        let contents = try String(contentsOf: projectFileURL, encoding: .utf8)

        XCTAssertTrue(contents.contains("FocusSessionMobileApp:"))
        XCTAssertTrue(contents.contains("platform: iOS"))
        XCTAssertTrue(contents.contains("- path: Apps/FocusSessionApp\n        excludes:\n          - Info.plist"))
        XCTAssertTrue(contents.contains("- path: Apps/FocusSessionMobileApp\n        excludes:\n          - Info.plist"))
    }

    func testCorePackageDeclaresIOS18Platform() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let packageFileURL = root.appendingPathComponent("Packages/FocusSessionCore/Package.swift")
        let contents = try String(contentsOf: packageFileURL, encoding: .utf8)

        XCTAssertTrue(contents.contains(".iOS(.v18)"))
    }

    func testIOSProjectUsesDedicatedMobileAppIconSet() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let projectFileURL = root.appendingPathComponent("project.yml")
        let contents = try String(contentsOf: projectFileURL, encoding: .utf8)

        XCTAssertTrue(contents.contains("FocusSessionMobileApp:"))
        XCTAssertTrue(contents.contains("ASSETCATALOG_COMPILER_APPICON_NAME: AppIconMobile"))
    }

    func testMobileAssetCatalogProvidesIOSAppIcons() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let contentsFileURL = root.appendingPathComponent(
            "Apps/FocusSessionMobileApp/Assets.xcassets/AppIconMobile.appiconset/Contents.json"
        )
        let contents = try String(contentsOf: contentsFileURL, encoding: .utf8)

        XCTAssertTrue(contents.contains("\"idiom\" : \"iphone\""))
        XCTAssertTrue(contents.contains("\"idiom\" : \"ipad\""))
        XCTAssertTrue(contents.contains("\"idiom\" : \"ios-marketing\""))
    }

    func testAppSurfaceThemeAddsUIKitBackedPromptedTextEditor() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/AppSurfaceTheme.swift")
        let contents = try String(contentsOf: fileURL, encoding: .utf8)

        XCTAssertTrue(contents.contains("os(iOS)"))
        XCTAssertTrue(contents.contains("UIViewRepresentable"))
        XCTAssertTrue(contents.contains("UITextView"))
    }

    func testMobileShellSourceExistsWithTabAndSplitNavigation() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = root.appendingPathComponent("Apps/FocusSessionMobileApp/UI/MobileAppShellView.swift")
        let contents = try String(contentsOf: fileURL, encoding: .utf8)

        XCTAssertTrue(contents.contains("TabView"))
        XCTAssertTrue(contents.contains("NavigationSplitView"))
        XCTAssertTrue(contents.contains("MobilePrimaryTab"))
    }

    func testMobileSpecificSourcesAvoidAppKitOnlyAPIs() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let appFileURL = root.appendingPathComponent("Apps/FocusSessionMobileApp/FocusSessionMobileApp.swift")
        let shellFileURL = root.appendingPathComponent("Apps/FocusSessionMobileApp/UI/MobileAppShellView.swift")

        let appContents = try String(contentsOf: appFileURL, encoding: .utf8)
        let shellContents = try String(contentsOf: shellFileURL, encoding: .utf8)

        XCTAssertFalse(appContents.contains("import AppKit"))
        XCTAssertFalse(appContents.contains("NSViewRepresentable"))
        XCTAssertFalse(shellContents.contains("import AppKit"))
        XCTAssertFalse(shellContents.contains("NSViewRepresentable"))
    }
}

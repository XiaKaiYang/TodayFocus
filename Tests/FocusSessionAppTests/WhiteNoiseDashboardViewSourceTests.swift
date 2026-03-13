import XCTest

final class WhiteNoiseDashboardViewSourceTests: XCTestCase {
    func testWhiteNoiseSidebarSectionIsWiredIntoAppShell() throws {
        let root = "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp"
        let appSectionSource = try String(
            contentsOfFile: "\(root)/UI/AppShell/AppSection.swift",
            encoding: .utf8
        )
        let appShellSource = try String(
            contentsOfFile: "\(root)/UI/AppShell/AppShellView.swift",
            encoding: .utf8
        )

        XCTAssertTrue(appSectionSource.contains("case whiteNoise"))
        XCTAssertTrue(appSectionSource.contains("case .whiteNoise"))
        XCTAssertTrue(appSectionSource.contains("\"White Noise\""))
        XCTAssertTrue(appSectionSource.contains("\"speaker.wave.3\""))

        XCTAssertTrue(appShellSource.contains("@StateObject private var whiteNoiseViewModel"))
        XCTAssertTrue(appShellSource.contains("let resolvedWhiteNoiseViewModel"))
        XCTAssertTrue(appShellSource.contains("case .whiteNoise"))
        XCTAssertTrue(appShellSource.contains("WhiteNoiseDashboardView(viewModel: whiteNoiseViewModel)"))
    }

    func testWhiteNoiseDashboardExposesAllRequestedSoundCards() throws {
        let source = try String(
            contentsOfFile: "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/WhiteNoise/WhiteNoiseDashboardView.swift",
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("Background sound"))
        XCTAssertTrue(source.contains("Session sound"))
        XCTAssertTrue(source.contains("Session end sound"))
        XCTAssertTrue(source.contains("Break sound"))
        XCTAssertTrue(source.contains("Break end sound"))
        XCTAssertTrue(source.contains("Volume"))
        XCTAssertTrue(source.contains("Clock Ticking"))
        XCTAssertTrue(source.contains("Ocean Waves"))
        XCTAssertTrue(source.contains("Gong"))
    }
}

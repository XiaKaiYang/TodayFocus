import XCTest

final class LocalSigningConfigurationSourceTests: XCTestCase {
    func testSharedXcconfigIncludesLocalSigningOverridesAndSafeDefaults() throws {
        let shared = try String(
            contentsOfFile: "/Users/xiakaiyang/Documents/New project/Config/Shared.xcconfig",
            encoding: .utf8
        )

        XCTAssertTrue(shared.contains("#include \"LocalSigning.xcconfig\""))
        XCTAssertTrue(shared.contains("FOCUSSESSION_CODE_SIGNING_ALLOWED = NO"))
        XCTAssertTrue(shared.contains("FOCUSSESSION_CODE_SIGNING_REQUIRED = NO"))
        XCTAssertTrue(shared.contains("FOCUSSESSION_CODE_SIGN_STYLE = Automatic"))
        XCTAssertTrue(shared.contains("FOCUSSESSION_CODE_SIGN_IDENTITY ="))
        XCTAssertTrue(shared.contains("FOCUSSESSION_DEVELOPMENT_TEAM ="))
    }

    func testProjectUsesSigningVariablesInsteadOfHardcodedNo() throws {
        let project = try String(
            contentsOfFile: "/Users/xiakaiyang/Documents/New project/project.yml",
            encoding: .utf8
        )

        XCTAssertTrue(project.contains("CODE_SIGNING_ALLOWED: $(FOCUSSESSION_CODE_SIGNING_ALLOWED)"))
        XCTAssertTrue(project.contains("CODE_SIGNING_REQUIRED: $(FOCUSSESSION_CODE_SIGNING_REQUIRED)"))
        XCTAssertTrue(project.contains("CODE_SIGN_STYLE: $(FOCUSSESSION_CODE_SIGN_STYLE)"))
        XCTAssertTrue(project.contains("CODE_SIGN_IDENTITY: $(FOCUSSESSION_CODE_SIGN_IDENTITY)"))
        XCTAssertTrue(project.contains("DEVELOPMENT_TEAM: $(FOCUSSESSION_DEVELOPMENT_TEAM)"))
    }
}

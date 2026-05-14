import XCTest

final class LocalizationSourceTests: XCTestCase {
    func testChineseLocalizationResourceCoversPrimaryNavigationAndFocusBattle() throws {
        let stringsURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Apps/FocusSessionApp/Resources/zh-Hans.lproj/Localizable.strings")

        let contents = try String(contentsOf: stringsURL, encoding: .utf8)

        XCTAssertTrue(contents.contains("\"app.section.tasks.title\" = \"今日\";"))
        XCTAssertTrue(contents.contains("\"app.section.pk.title\" = \"专注对战\";"))
        XCTAssertTrue(contents.contains("\"PK Tables\" = \"专注对战大厅\";"))
        XCTAssertTrue(contents.contains("\"Create Table\" = \"创建桌子\";"))
        XCTAssertTrue(contents.contains("\"Join by Code\" = \"输入邀请码\";"))
        XCTAssertTrue(contents.contains("\"White Noise\" = \"白噪音\";"))
        XCTAssertTrue(contents.contains("\"app.section.account.title\" = \"个人主页\";"))
        XCTAssertTrue(contents.contains("\"Settings\" = \"设置\";"))
        XCTAssertTrue(contents.contains("\"Focus Defaults\" = \"专注默认值\";"))
        XCTAssertTrue(contents.contains("\"Control background sound, session sound, session end sound, break sound, and break end sound from one dedicated workspace.\" = \"在一个专用空间里统一管理背景声、专注提示音、专注结束音、休息提示音和休息结束音。\";"))
    }
}

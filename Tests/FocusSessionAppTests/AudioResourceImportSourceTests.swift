import Foundation
import XCTest

final class AudioResourceImportSourceTests: XCTestCase {
    private let projectRoot = "/Users/xiakaiyang/Documents/New project"
    private let audioRoot = "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/Resources/Audio"

    func testImportedAudioTreeContainsAllExpectedDirectoriesAndFiles() throws {
        let fileManager = FileManager.default

        XCTAssertTrue(fileManager.fileExists(atPath: "\(audioRoot)/Session/SoundEffects"))
        XCTAssertTrue(fileManager.fileExists(atPath: "\(audioRoot)/Session/WhiteNoise"))
        XCTAssertTrue(fileManager.fileExists(atPath: "\(audioRoot)/TickTick/SoundEffects"))

        XCTAssertTrue(fileManager.fileExists(atPath: "\(audioRoot)/Session/SoundEffects/light.wav"))
        XCTAssertTrue(fileManager.fileExists(atPath: "\(audioRoot)/Session/WhiteNoise/Ocean Waves.mp3"))
        XCTAssertTrue(fileManager.fileExists(atPath: "\(audioRoot)/TickTick/SoundEffects/default.wav"))
        XCTAssertTrue(fileManager.fileExists(atPath: "\(audioRoot)/import-manifest.json"))

        let enumerator = fileManager.enumerator(atPath: audioRoot)
        let audioFileCount = (enumerator?.allObjects as? [String] ?? []).filter { path in
            let lowercased = path.lowercased()
            return lowercased.hasSuffix(".wav")
                || lowercased.hasSuffix(".mp3")
                || lowercased.hasSuffix(".aac")
                || lowercased.hasSuffix(".m4a")
        }.count

        XCTAssertEqual(audioFileCount, 33)
    }

    func testImportManifestTracksAllImportedFiles() throws {
        let manifestURL = URL(fileURLWithPath: "\(audioRoot)/import-manifest.json")
        let data = try Data(contentsOf: manifestURL)
        let manifest = try JSONSerialization.jsonObject(with: data) as? [[String: String]]

        XCTAssertEqual(manifest?.count, 33)
        XCTAssertTrue(
            manifest?.contains(where: {
                $0["sourceApp"] == "Session"
                    && $0["destination"] == "Session/SoundEffects/light.wav"
                    && $0["sourcePath"] == "/Applications/Session.app/Contents/Resources/light.wav"
            }) == true
        )
        XCTAssertTrue(
            manifest?.contains(where: {
                $0["sourceApp"] == "Session"
                    && $0["destination"] == "Session/WhiteNoise/Ocean Waves.mp3"
                    && $0["sourcePath"] == "/Applications/Session.app/Contents/Resources/Assets/White Noise/Ocean Waves.mp3"
            }) == true
        )
        XCTAssertTrue(
            manifest?.contains(where: {
                $0["sourceApp"] == "TickTick"
                    && $0["destination"] == "TickTick/SoundEffects/default.wav"
                    && $0["sourcePath"] == "/Applications/TickTick.app/Contents/Resources/default.wav"
            }) == true
        )
    }

    func testProjectCopiesAudioFolderIntoAppResources() throws {
        let project = try String(
            contentsOfFile: "\(projectRoot)/FocusSession.xcodeproj/project.pbxproj",
            encoding: .utf8
        )

        XCTAssertTrue(project.contains("path = Audio;"))
        XCTAssertTrue(project.contains("import-manifest.json in Resources"))
        XCTAssertTrue(project.contains("Ocean Waves.mp3 in Resources"))
        XCTAssertTrue(project.contains("default.wav in Resources"))
        XCTAssertTrue(project.contains("light.wav in Resources"))
    }
}

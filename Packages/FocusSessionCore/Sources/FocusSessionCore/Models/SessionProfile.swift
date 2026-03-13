import Foundation

public struct SessionProfile: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var focusDurationSeconds: Int
    public var breakDurationSeconds: Int
    public var autoBreak: Bool
    public var blockingProfileID: UUID?
    public var backgroundSoundName: String?

    public init(
        id: UUID = UUID(),
        name: String,
        focusDurationSeconds: Int = 25 * 60,
        breakDurationSeconds: Int = 5 * 60,
        autoBreak: Bool = true,
        blockingProfileID: UUID? = nil,
        backgroundSoundName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.focusDurationSeconds = focusDurationSeconds
        self.breakDurationSeconds = breakDurationSeconds
        self.autoBreak = autoBreak
        self.blockingProfileID = blockingProfileID
        self.backgroundSoundName = backgroundSoundName
    }
}

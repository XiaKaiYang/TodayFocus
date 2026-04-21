import XCTest
@testable import FocusSession

@MainActor
final class PKRepositoryFactoryTests: XCTestCase {
    func testFactoryReturnsLocalRepositoriesWhenCloudUnavailable() {
        let roomRepository = PKRepositoryFactory.makeRoomRepository(cloudAvailable: false)
        let sessionRepository = PKRepositoryFactory.makePKSessionRepository(cloudAvailable: false)
        let leaderboardRepository = PKRepositoryFactory.makeLeaderboardRepository(cloudAvailable: false)

        XCTAssertTrue(roomRepository is LocalRoomRepository)
        XCTAssertTrue(sessionRepository is LocalPKSessionRepository)
        XCTAssertTrue(leaderboardRepository is LocalLeaderboardRepository)
    }

    func testFactoryReturnsCloudRepositoriesWhenCloudAvailable() {
        let roomRepository = PKRepositoryFactory.makeRoomRepository(cloudAvailable: true)
        let sessionRepository = PKRepositoryFactory.makePKSessionRepository(cloudAvailable: true)
        let leaderboardRepository = PKRepositoryFactory.makeLeaderboardRepository(cloudAvailable: true)

        XCTAssertTrue(roomRepository is RoomRepository)
        XCTAssertTrue(sessionRepository is PKSessionRepository)
        XCTAssertTrue(leaderboardRepository is LeaderboardRepository)
    }
}

import SwiftData
import XCTest
@testable import FocusSession

@MainActor
final class TasksViewModelSoundTests: XCTestCase {
    func testMarkTaskCompletedPlaysEndingSoonSoundAfterSuccessfulCompletion() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let soundPlayer = RecordingSoundEffectPlayer()
        let task = FocusTask(title: "Complete checkbox path", estimatedMinutes: 25)
        try repository.save(task)
        let viewModel = TasksViewModel(
            repository: repository,
            soundEffectPlayer: soundPlayer
        )

        viewModel.markTaskCompleted(task)

        let storedTask = try XCTUnwrap(
            try repository.fetchAll().first(where: { $0.id == task.id })
        )
        XCTAssertTrue(storedTask.isCompleted)
        XCTAssertEqual(
            soundPlayer.requests,
            [SoundPlaybackRequest(assetName: "ending-soon.wav", volume: 1)]
        )
    }
}

private final class RecordingSoundEffectPlayer: SoundEffectPlaying {
    private(set) var requests: [SoundPlaybackRequest] = []

    func play(_ request: SoundPlaybackRequest) {
        requests.append(request)
    }
}

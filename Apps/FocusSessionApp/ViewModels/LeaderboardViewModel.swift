import Foundation

struct LeaderboardEntry: Equatable, Identifiable {
    var id: String { userID }
    let userID: String
    let displayName: String
    let focusMinutes: Int
    let violationCount: Int
    let sessionCount: Int
}

@MainActor
final class LeaderboardViewModel: ObservableObject {
    @Published private(set) var dailyEntries: [LeaderboardEntry] = []
    @Published private(set) var weeklyEntries: [LeaderboardEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let repository: any LeaderboardRepositoryProtocol

    init(repository: any LeaderboardRepositoryProtocol = LeaderboardRepository()) {
        self.repository = repository
    }

    func load(roomID: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let dayKey = LeaderboardRepository.dayKey()
            let weekKey = LeaderboardRepository.weekKey()
            let daily = try await repository.fetchBuckets(roomID: roomID, period: .daily, periodKey: dayKey)
            let weekly = try await repository.fetchBuckets(roomID: roomID, period: .weekly, periodKey: weekKey)
            dailyEntries = daily
                .sorted { $0.focusMinutes > $1.focusMinutes }
                .map { LeaderboardEntry(userID: $0.userID, displayName: $0.userID, focusMinutes: $0.focusMinutes, violationCount: $0.violationCount, sessionCount: $0.sessionCount) }
            weeklyEntries = weekly
                .sorted { $0.focusMinutes > $1.focusMinutes }
                .map { LeaderboardEntry(userID: $0.userID, displayName: $0.userID, focusMinutes: $0.focusMinutes, violationCount: $0.violationCount, sessionCount: $0.sessionCount) }
        } catch {
            errorMessage = "Unable to load leaderboard."
        }
    }
}

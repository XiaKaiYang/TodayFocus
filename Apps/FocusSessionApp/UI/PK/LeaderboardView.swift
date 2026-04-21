import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var viewModel: LeaderboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if viewModel.isLoading {
                ProgressView("Loading leaderboard…")
                    .frame(maxWidth: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(Color(red: 1.0, green: 0.50, blue: 0.52))
                    .font(.callout)
            } else {
                leaderboardSection(title: "Today", entries: viewModel.dailyEntries)
                leaderboardSection(title: "This Week", entries: viewModel.weeklyEntries)
            }
        }
        .padding(20)
    }

    @ViewBuilder
    private func leaderboardSection(title: String, entries: [LeaderboardEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            if entries.isEmpty {
                Text("No data yet.")
                    .font(.callout)
                    .foregroundStyle(AppSurfaceTheme.secondaryText)
            } else {
                ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                    LeaderboardRowView(rank: index + 1, entry: entry)
                }
            }
        }
    }
}

private struct LeaderboardRowView: View {
    let rank: Int
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.secondaryText)
                .frame(width: 24, alignment: .trailing)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppSurfaceTheme.primaryText)
                Text("\(entry.focusMinutes) min · \(entry.sessionCount) sessions")
                    .font(.caption)
                    .foregroundStyle(AppSurfaceTheme.secondaryText)
            }

            Spacer()

            if entry.violationCount > 0 {
                Text("\(entry.violationCount) ⚠️")
                    .font(.caption)
                    .foregroundStyle(Color(red: 1.0, green: 0.50, blue: 0.52))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppCardSurface(style: .elevated, cornerRadius: 14))
    }
}

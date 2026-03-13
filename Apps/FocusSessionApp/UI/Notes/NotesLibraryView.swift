import SwiftUI

struct NotesLibraryView: View {
    @StateObject private var viewModel: NotesLibraryViewModel

    init(viewModel: NotesLibraryViewModel = NotesLibraryViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        GeometryReader { geometry in
            let widthTier = AppResponsiveWidthTier.detail(for: geometry.size.width)
            let notesListWidth = min(360, max(280, geometry.size.width * 0.30))
            let contentInsets = DetailDashboardLayoutMetrics.contentInsets(for: widthTier)

            ZStack {
                AppCanvasBackground()

                VStack(alignment: .leading, spacing: 24) {
                    pageHeader

                    Group {
                        if widthTier == .compact {
                            VStack(alignment: .leading, spacing: 24) {
                                notesListColumn

                                noteDetailColumn
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                            }
                        } else {
                            HStack(alignment: .top, spacing: 24) {
                                notesListColumn
                                    .frame(width: notesListWidth)

                                noteDetailColumn
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .padding(.top, contentInsets.top)
                .padding(.leading, contentInsets.leading)
                .padding(.trailing, contentInsets.trailing)
                .padding(.bottom, contentInsets.bottom)
            }
        }
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(Color(red: 1.0, green: 0.50, blue: 0.52))
            }

            DashboardTimeNavigator(
                selectedScope: viewModel.selectedScope,
                referenceTitle: viewModel.referenceTitle,
                timeStrip: viewModel.timeStrip,
                onSelectScope: viewModel.setScope,
                onMoveBackward: viewModel.moveBackward,
                onMoveForward: viewModel.moveForward,
                onSelectDate: viewModel.selectDate
            )
        }
    }

    private var notesListColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if viewModel.entries.isEmpty {
                        emptyListState
                    } else {
                        ForEach(viewModel.entries) { entry in
                            noteRow(entry)
                        }
                    }
                }
            }
        }
    }

    private var noteDetailColumn: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let selectedEntry = viewModel.selectedEntry {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(selectedEntry.title)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(AppSurfaceTheme.primaryText)

                            HStack(spacing: 12) {
                                if let moodEmoji = selectedEntry.moodEmoji {
                                    Text(moodEmoji)
                                }
                                Text(selectedEntry.endedAtText)
                                Text(selectedEntry.relativeEndedText)
                                Text(selectedEntry.durationText)
                            }
                            .font(.headline)
                            .foregroundStyle(AppSurfaceTheme.secondaryText)
                        }

                        Spacer()

                        Button(role: .destructive) {
                            viewModel.deleteSelectedEntry()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .buttonStyle(
                            AppGlassButtonStyle(
                                cornerRadius: 999,
                                tint: Color(red: 0.92, green: 0.30, blue: 0.32),
                                foregroundColor: Color(red: 0.63, green: 0.18, blue: 0.20)
                            )
                        )
                    }
                }

                ScrollView {
                    Text(selectedEntry.body)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .textSelection(.enabled)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.emptyDetailTitle)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.primaryText)

                    Text(viewModel.emptyDetailMessage)
                        .font(.title3)
                        .foregroundStyle(AppSurfaceTheme.secondaryText)
                }
            }
        }
        .padding(28)
        .background(AppCardSurface(style: .standard, cornerRadius: 30))
    }

    private var emptyListState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.emptyListTitle)
                .font(.headline)
                .foregroundStyle(AppSurfaceTheme.primaryText)

            Text(viewModel.emptyListMessage)
                .font(.body)
                .foregroundStyle(AppSurfaceTheme.secondaryText)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppCardSurface(style: .soft, cornerRadius: 24))
    }

    private func noteRow(_ entry: NotesLibraryEntry) -> some View {
        let isSelected = viewModel.selectedEntryID == entry.id

        return Button {
            viewModel.selectEntry(entry)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(red: 0.94, green: 0.35, blue: 0.37))
                        .frame(width: 8, height: 44)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.title)
                            .font(.headline)
                            .foregroundStyle(AppSurfaceTheme.primaryText)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            if let moodEmoji = entry.moodEmoji {
                                Text(moodEmoji)
                            }

                            Text(entry.endedAtText)
                                .font(.caption)
                                .foregroundStyle(AppSurfaceTheme.mutedText)
                        }

                        Text(entry.preview)
                            .font(.subheadline)
                            .foregroundStyle(AppSurfaceTheme.secondaryText)
                            .lineLimit(3)
                    }

                    Spacer()

                    Text(entry.durationText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppSurfaceTheme.secondaryText)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AppCardSurface(
                    style: isSelected ? .sidebarSelected : .elevated,
                    cornerRadius: 24
                )
            )
        }
        .buttonStyle(.plain)
    }
}

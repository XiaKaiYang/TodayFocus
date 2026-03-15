import SwiftUI
import FocusSessionCore

struct CurrentSessionView: View {
    @StateObject private var viewModel: CurrentSessionViewModel
    @State private var isHoveringCenteredTimer = false
    @FocusState private var isRuntimeNoteComposerFocused: Bool
    private let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(viewModel: CurrentSessionViewModel = CurrentSessionViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        GeometryReader { geometry in
            let widthTier = AppResponsiveWidthTier.detail(for: geometry.size.width)
            let layout = CurrentSessionLayoutMetrics.make(
                widthTier: widthTier,
                isCompactHeight: geometry.size.height < 820,
                phase: viewModel.sessionState.phase
            )
            let scene = CurrentSessionSceneConfiguration.make(phase: viewModel.sessionState.phase)

            ZStack {
                backgroundLayer(for: scene)

                contentContainer(
                    layout: layout,
                    scene: scene,
                    availableWidth: geometry.size.width
                )
                .padding(20)

                if viewModel.showReflectionComposer {
                    reflectionComposerOverlay(
                        layout: layout,
                        availableWidth: geometry.size.width
                    )
                }
            }
            .onReceive(countdownTimer) { currentDate in
                viewModel.handleTimelineTick(at: currentDate)
            }
            .onChange(of: viewModel.sessionState.phase) { oldPhase, newPhase in
                if phaseUsesNotesWorkspace(oldPhase) && !phaseUsesNotesWorkspace(newPhase) {
                    isHoveringCenteredTimer = false
                    isRuntimeNoteComposerFocused = false
                }
            }
        }
    }

    @ViewBuilder
    private func backgroundLayer(for scene: CurrentSessionSceneConfiguration) -> some View {
        if scene.showsNotesWorkspace {
            AppCanvasBackground()
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color(red: 0.95, green: 0.90, blue: 0.86).opacity(0.10),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .ignoresSafeArea()
        } else {
            AppCanvasBackground()
        }
    }

    @ViewBuilder
    private func contentContainer(
        layout: CurrentSessionLayoutMetrics,
        scene: CurrentSessionSceneConfiguration,
        availableWidth: CGFloat
    ) -> some View {
        ZStack {
            if scene.showsNotesWorkspaceChrome {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(Color.white.opacity(0.22))
            } else if !layout.usesTransparentSetupContainer {
                AppCardSurface(style: .sidebarSelected, cornerRadius: 34)
            }

            if scene.showsNotesWorkspace {
                notesWorkspace(
                    layout: layout,
                    scene: scene,
                    availableWidth: availableWidth
                )
            } else if scene.showsFocusClockStage {
                setupStage(
                    layout: layout,
                    availableWidth: availableWidth
                )
            }
        }
        .overlay {
            if scene.showsNotesWorkspaceChrome {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(AppSurfaceTheme.outline.opacity(0.85), lineWidth: 1)
            } else if !layout.usesTransparentSetupContainer {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(AppSurfaceTheme.outline, lineWidth: 1)
            }
        }
    }

    private func reflectionComposerOverlay(
        layout: CurrentSessionLayoutMetrics,
        availableWidth: CGFloat
    ) -> some View {
        let isReflectionActionDisabled = viewModel.selectedReflectionMood == nil
        let cardWidth = min(
            layout.setupHeroMaxWidth + 140,
            max(availableWidth - 64, 320)
        )
        let noteWidth = min(
            layout.setupHeroMaxWidth + 80,
            max(availableWidth - 112, 260)
        )

        return ZStack {
            Color.black.opacity(0.22)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("🥳")
                    .font(.system(size: 42))

                HStack(spacing: 18) {
                    reflectionMoodButton(
                        emoji: "🤩",
                        title: "Focused",
                        mood: .focused
                    )
                    reflectionMoodButton(
                        emoji: "😐",
                        title: "Neutral",
                        mood: .neutral
                    )
                    reflectionMoodButton(
                        emoji: "😞",
                        title: "Distracted",
                        mood: .distracted
                    )
                }

                AppPromptedTextEditor(
                    prompt: "Leave an optional note about how this session felt.",
                    text: $viewModel.sessionNotes,
                    fontSize: layout.notesBodyFontSize,
                    cornerRadius: 24,
                    horizontalInset: 18,
                    verticalInset: 16
                )
                .frame(width: noteWidth)
                .frame(minHeight: 150)

                HStack(spacing: 12) {
                    Button("Submit") {
                        viewModel.submitReflection()
                    }
                    .buttonStyle(AppAccentButtonStyle())
                    .frame(maxWidth: .infinity)
                    .disabled(isReflectionActionDisabled)
                    .opacity(isReflectionActionDisabled ? 0.45 : 1)

                    Button("Submit & Continue") {
                        viewModel.submitReflectionAndContinueEpisode()
                    }
                    .buttonStyle(
                        AppGlassButtonStyle(
                            cornerRadius: 16,
                            tint: Color(red: 0.88, green: 0.78, blue: 0.66)
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .disabled(isReflectionActionDisabled)
                    .opacity(isReflectionActionDisabled ? 0.45 : 1)
                }
            }
            .padding(24)
            .frame(width: cardWidth)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color(red: 0.98, green: 0.97, blue: 0.95))

                    AppCardSurface(style: .elevated, cornerRadius: 30)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(AppSurfaceTheme.outline.opacity(0.92), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 22, y: 12)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private func reflectionMoodButton(
        emoji: String,
        title: String,
        mood: SessionReflectionMood
    ) -> some View {
        let isSelected = viewModel.selectedReflectionMood == mood

        return Button {
            viewModel.selectReflectionMood(mood)
        } label: {
            VStack(spacing: 10) {
                Text(emoji)
                    .font(.system(size: 34))

                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.primaryText)
            }
            .frame(maxWidth: .infinity, minHeight: 92)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        isSelected
                            ? runtimeAccentColor.opacity(0.22)
                            : Color.white.opacity(0.62)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        isSelected
                            ? runtimeAccentColor.opacity(0.82)
                            : AppSurfaceTheme.outline.opacity(0.72),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func setupStage(
        layout: CurrentSessionLayoutMetrics,
        availableWidth: CGFloat
    ) -> some View {
        let stageWidth = min(
            layout.setupStageContentMaxWidth,
            max(availableWidth - (layout.leftColumnHorizontalPadding * 2), 0)
        )

        return ZStack {
            setupStageGlow(layout: layout)

            VStack(spacing: 0) {
                setupHero(layout: layout)
                    .frame(maxWidth: stageWidth)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, layout.leftColumnHorizontalPadding)
            .padding(.vertical, layout.leftColumnVerticalPadding)
        }
    }

    private func setupStageGlow(layout: CurrentSessionLayoutMetrics) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.92, green: 0.31, blue: 0.33).opacity(0.22),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 24,
                        endRadius: 240
                    )
                )
                .frame(width: layout.dialSize * 2.1, height: layout.dialSize * 2.1)
                .offset(x: -layout.dialSize * 0.55, y: layout.dialSize * 0.72)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.06),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 16,
                        endRadius: 180
                    )
                )
                .frame(width: layout.dialSize * 1.15, height: layout.dialSize * 1.15)
                .offset(x: layout.dialSize * 0.60, y: -layout.dialSize * 0.36)
        }
    }

    private func setupHero(layout: CurrentSessionLayoutMetrics) -> some View {
        VStack(spacing: layout.leftColumnSpacing) {
            setupHeader(layout: layout)

            taskSelector(layout: layout)

            VStack(spacing: max(14, layout.leftColumnSpacing - 2)) {
                clockStage(layout: layout)
                timeReadout(layout: layout)

                if viewModel.canConfigureSession {
                    durationControlRow(layout: layout)
                    startSessionButton
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private func setupHeader(layout: CurrentSessionLayoutMetrics) -> some View {
        VStack(spacing: 10) {
            Text("Current Session")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)
        }
    }

    private func notesWorkspace(
        layout: CurrentSessionLayoutMetrics,
        scene: CurrentSessionSceneConfiguration,
        availableWidth: CGFloat
    ) -> some View {
        ZStack {
            if scene.showsEmbeddedWorkspaceBackground {
                workspaceBackground
            }

            VStack(spacing: 0) {
                if scene.showsRunningStatusBar {
                    runningStatusBar(layout: layout)
                }

                Spacer(minLength: 0)

                centeredRuntimeStage(
                    layout: layout,
                    availableWidth: availableWidth
                )

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
    }

    private var workspaceBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.94, blue: 0.90),
                    Color(red: 0.94, green: 0.95, blue: 0.97),
                    Color(red: 0.92, green: 0.93, blue: 0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            FocusAmbientStarfieldView()
                .opacity(0.34)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.28),
                    Color.clear,
                    Color(red: 0.86, green: 0.89, blue: 0.95).opacity(0.22)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func runningStatusBar(layout: CurrentSessionLayoutMetrics) -> some View {
        HStack(spacing: 12) {
            Spacer(minLength: 0)

            if viewModel.canPauseSession {
                statusActionButton(
                    title: "Pause",
                    fontSize: layout.statusActionFontSize,
                    action: viewModel.pauseSession
                )
            }

            if viewModel.canResumeSession {
                statusActionButton(
                    title: "Resume",
                    fontSize: layout.statusActionFontSize,
                    action: viewModel.resumeSession
                )
            }

            if viewModel.canFinishSession {
                statusActionButton(
                    title: "Finish",
                    fontSize: layout.statusActionFontSize,
                    isPrimary: true,
                    action: viewModel.finishSession
                )
            }

            if viewModel.canPrepareNextSession {
                statusActionButton(
                    title: "New Session",
                    fontSize: layout.statusActionFontSize,
                    isPrimary: true,
                    action: viewModel.prepareNextSession
                )
            }
        }
    }

    private func centeredRuntimeStage(
        layout: CurrentSessionLayoutMetrics,
        availableWidth: CGFloat
    ) -> some View {
        let revealsNoteComposer = CurrentSessionSceneConfiguration.shouldRevealRuntimeNoteComposer(
            phase: viewModel.sessionState.phase,
            isHoveringCenteredTimer: isHoveringCenteredTimer,
            isEditingNotes: isRuntimeNoteComposerFocused
        )
        let stageWidth = min(
            layout.setupHeroMaxWidth + 120,
            max(availableWidth - 64, 300)
        )

        return TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { context in
            let floatingOffset = runtimeTimerOffset(at: context.date)

            VStack(spacing: revealsNoteComposer ? 24 : 10) {
                VStack(spacing: 10) {
                    Text(viewModel.remainingTimeText(at: context.date))
                        .font(
                            .system(
                                size: layout.timeReadoutFontSize * 3.2,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .monospacedDigit()
                        .foregroundStyle(AppSurfaceTheme.primaryText)

                    Text(viewModel.phaseText)
                        .font(.system(size: layout.notesBodyFontSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.secondaryText)
                        .textCase(.uppercase)
                        .tracking(1.6)
                }
                .offset(floatingOffset)
                .scaleEffect(isHoveringCenteredTimer ? 1.015 : 1.0)

                if revealsNoteComposer {
                    runtimeNoteComposer(
                        layout: layout,
                        availableWidth: availableWidth
                    )
                        .transition(
                            .move(edge: .top)
                            .combined(with: .opacity)
                        )
                }
            }
            .frame(maxWidth: stageWidth)
            .contentShape(Rectangle())
            .onHover { isHovering in
                withAnimation(.easeOut(duration: 0.18)) {
                    isHoveringCenteredTimer = isHovering
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: revealsNoteComposer)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func runtimeNoteComposer(
        layout: CurrentSessionLayoutMetrics,
        availableWidth: CGFloat
    ) -> some View {
        let noteWidth = min(
            layout.setupHeroMaxWidth + 80,
            max(availableWidth - 88, 260)
        )

        return AppPromptedTextEditor(
            prompt: "Write down what you learned, what distracted you, or what still feels fuzzy.",
            text: $viewModel.sessionNotes,
            fontSize: layout.notesBodyFontSize,
            cornerRadius: 30,
            horizontalInset: layout.noteEditorHorizontalInset,
            verticalInset: layout.noteEditorVerticalInset,
            focus: Binding(
                get: { isRuntimeNoteComposerFocused },
                set: { isRuntimeNoteComposerFocused = $0 }
            )
        )
        .frame(width: noteWidth)
        .frame(minHeight: max(180, layout.noteEditorMinHeight - 110))
    }

    @ViewBuilder
    private func statusSummaryPill(layout: CurrentSessionLayoutMetrics) -> some View {
        if viewModel.canPrepareNextSession {
            HStack(spacing: 12) {
                Circle()
                    .fill(runtimeAccentColor)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.phaseText)
                        .font(.system(size: layout.statusValueFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.primaryText)

                    Text(viewModel.recentSessions.first?.durationText ?? "Saved to history")
                        .font(.system(size: layout.statusMetaFontSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.secondaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(statusPillBackground)
            .overlay(statusPillOverlay)
        } else {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                HStack(spacing: 12) {
                    Circle()
                        .fill(runtimeAccentColor)
                        .frame(width: 10, height: 10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.remainingTimeText(at: context.date))
                            .font(.system(size: layout.statusValueFontSize, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(AppSurfaceTheme.primaryText)

                        Text(viewModel.phaseText)
                            .font(.system(size: layout.statusMetaFontSize, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.secondaryText)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(statusPillBackground)
                .overlay(statusPillOverlay)
            }
        }
    }

    private var statusPillBackground: some View {
        AppGlassCapsuleSurface(
            tint: Color(red: 0.58, green: 0.67, blue: 0.83)
        )
    }

    private var statusPillOverlay: some View {
        Capsule(style: .continuous)
            .stroke(Color.clear, lineWidth: 0)
    }

    private func statusActionButton(
        title: String,
        fontSize: CGFloat,
        isPrimary: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(isPrimary ? AppSurfaceTheme.accentText : AppSurfaceTheme.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isPrimary {
                            Capsule(style: .continuous)
                                .fill(AppSurfaceTheme.accentGradient)
                        } else {
                            AppGlassCapsuleSurface(
                                tint: Color(red: 0.58, green: 0.67, blue: 0.83)
                            )
                        }
                    }
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(isPrimary ? Color.white.opacity(0.10) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var runtimeAccentColor: Color {
        switch viewModel.sessionState.phase {
        case .focusing:
            Color(red: 1.0, green: 0.35, blue: 0.38)
        case .focusPaused:
            Color(red: 0.92, green: 0.74, blue: 0.34)
        case .breakRunning, .breakPaused:
            Color(red: 0.40, green: 0.78, blue: 0.72)
        case .reflecting:
            Color(red: 0.93, green: 0.73, blue: 0.24)
        case .completed:
            Color(red: 0.42, green: 0.82, blue: 0.64)
        case .idle, .abandoned:
            Color.white
        }
    }

    private func taskSelector(layout: CurrentSessionLayoutMetrics) -> some View {
        let selectorTitle = viewModel.selectedTaskTitle
            ?? (viewModel.availableTaskSelections.isEmpty
                ? "Create a task in Today first"
                : "Select a Today task")
        let selectorOptions = viewModel.availableTaskSelections.map { selection in
            AppDropdownOption(
                value: selection,
                title: selection.selectorTitle,
                subtitle: "\(selection.estimatedMinutes) min"
            )
        }

        return VStack(spacing: 10) {
            Text("Today Task")
                .font(.system(size: layout.intentionTitleFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.secondaryText)
                .textCase(.uppercase)

            AppDropdownField(
                selection: viewModel.selectedTaskSelection,
                selectedTitle: selectorTitle,
                options: selectorOptions,
                isInteractive: viewModel.canConfigureSession && !viewModel.availableTaskSelections.isEmpty,
                height: layout.intentionInputHeight,
                cornerRadius: 20,
                fillColor: AppSurfaceTheme.taskSelectorWarmBorder.opacity(0.035),
                strokeColor: AppSurfaceTheme.taskSelectorWarmBorder.opacity(0.42),
                textColor: viewModel.canConfigureSession && !viewModel.availableTaskSelections.isEmpty
                    ? AppSurfaceTheme.primaryText
                    : AppSurfaceTheme.taskSelectorWarmText,
                glyphColor: viewModel.canConfigureSession && !viewModel.availableTaskSelections.isEmpty
                    ? AppSurfaceTheme.taskSelectorWarmGlyph
                    : AppSurfaceTheme.taskSelectorWarmText.opacity(0.82),
                subtitleColor: AppSurfaceTheme.secondaryText,
                popoverTint: Color(red: 0.80, green: 0.67, blue: 0.60)
            ) { selection in
                viewModel.selectTask(selection)
            }
        }
        .frame(maxWidth: layout.taskSelectorMaxWidth)
    }

    private func clockStage(layout: CurrentSessionLayoutMetrics) -> some View {
        FocusClockDialView(
            progress: viewModel.dialConfigurationProgress,
            minutes: viewModel.durationMinutes,
            showsCenterReadout: layout.dialShowsCenterReadout,
            usesSoftPlatter: layout.dialUsesSoftPlatter,
            hubDiameter: layout.dialHubDiameter,
            handShadowRadius: layout.dialHandShadowRadius,
            isInteractive: true
        ) { normalizedValue in
            viewModel.updateDurationFromDial(normalizedValue: normalizedValue)
        }
        .frame(width: layout.dialSize, height: layout.dialSize)
    }

    private func timeReadout(layout: CurrentSessionLayoutMetrics) -> some View {
        Text("\(viewModel.durationMinutes) min")
            .font(.system(size: layout.timeReadoutFontSize, weight: .medium, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(AppSurfaceTheme.primaryText)
    }

    private func durationControlRow(layout: CurrentSessionLayoutMetrics) -> some View {
        HStack(spacing: layout.leftColumnSpacing) {
            durationButton(
                title: "-5",
                systemImage: "minus",
                isEnabled: viewModel.durationMinutes > FocusClockDialMath.minMinutes
            ) {
                adjustDuration(byMinutes: -5)
            }

            Text("Set your focus length")
                .font(.system(size: layout.durationControlFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)
                .padding(.horizontal, layout.leftColumnSpacing + 4)
                .padding(.vertical, 12)
                .background(
                    AppGlassCapsuleSurface(
                        tint: Color(red: 0.58, green: 0.67, blue: 0.83)
                    )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.clear, lineWidth: 1)
                )

            durationButton(
                title: "+5",
                systemImage: "plus",
                isEnabled: viewModel.durationMinutes < FocusClockDialMath.maxMinutes
            ) {
                adjustDuration(byMinutes: 5)
            }
        }
    }

    private var startSessionButton: some View {
        Button("Start Session") {
            viewModel.startSession()
        }
        .buttonStyle(.plain)
        .font(.system(size: 18, weight: .semibold, design: .rounded))
        .foregroundStyle(AppSurfaceTheme.accentText)
        .padding(.horizontal, 34)
        .padding(.vertical, 14)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.93, green: 0.29, blue: 0.30),
                            Color(red: 0.74, green: 0.22, blue: 0.23)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: Color(red: 0.93, green: 0.29, blue: 0.30).opacity(0.35), radius: 16, y: 10)
        .disabled(!viewModel.canStartSelectedTaskSession)
        .opacity(viewModel.canStartSelectedTaskSession ? 1 : 0.45)
    }

    private func noteEditor(layout: CurrentSessionLayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Note")
                .font(.system(size: layout.notesTitleFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            AppPromptedTextEditor(
                prompt: "Write down what you learned, what distracted you, or what still feels fuzzy.",
                text: $viewModel.sessionNotes,
                fontSize: layout.notesBodyFontSize,
                cornerRadius: 30,
                horizontalInset: layout.noteEditorHorizontalInset,
                verticalInset: layout.noteEditorVerticalInset
            )
            .frame(maxWidth: .infinity, minHeight: layout.noteEditorMinHeight)
        }
    }

    private func historyNotesSection(layout: CurrentSessionLayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("History Notes")
                    .font(.system(size: layout.recentSectionTitleFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.primaryText)

                Spacer()

                Text("\(viewModel.recentSessions.count) shown")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.secondaryText)
            }

            if viewModel.recentSessions.isEmpty {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(AppSurfaceTheme.outline.opacity(0.85), lineWidth: 1)
                    )
                    .overlay {
                        Text("No history notes yet. Finish one focused session and the note will appear here.")
                            .font(.system(size: layout.supportingCopyFontSize, weight: .medium, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(28)
                    }
                    .frame(minHeight: 160)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.recentSessions) { session in
                            historyNoteRow(session, layout: layout)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxWidth: .infinity, maxHeight: layout.historySectionMaxHeight)
            }
        }
    }

    private func historyNoteRow(
        _ session: RecentSessionSummary,
        layout: CurrentSessionLayoutMetrics
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.title)
                    .font(.system(size: layout.recentSessionTitleFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.primaryText)
                    .lineLimit(1)

                Spacer()

                Text(session.relativeEndedText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.secondaryText)
            }

            Text(session.notePreview.isEmpty ? "No notes captured for this session." : session.notePreview)
                .font(.system(size: layout.supportingCopyFontSize, weight: .medium, design: .rounded))
                .foregroundStyle(
                    session.notePreview.isEmpty
                    ? AppSurfaceTheme.mutedText
                    : AppSurfaceTheme.secondaryText
                )
                .lineLimit(3)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppSurfaceTheme.outline.opacity(0.85), lineWidth: 1)
        )
    }

    private func durationButton(
        title: String,
        systemImage: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundStyle(isEnabled ? AppSurfaceTheme.primaryText : AppSurfaceTheme.secondaryText)
            .frame(width: 60, height: 60)
            .background(
                AppGlassCircleSurface(
                    tint: isEnabled
                    ? Color(red: 0.58, green: 0.67, blue: 0.83)
                    : Color(red: 0.45, green: 0.48, blue: 0.55)
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private func runtimeTimerOffset(at date: Date) -> CGSize {
        let time = date.timeIntervalSinceReferenceDate
        return CGSize(
            width: sin(time * 0.42) * 10,
            height: cos(time * 0.31) * 7
        )
    }

    private func phaseUsesNotesWorkspace(_ phase: SessionPhase) -> Bool {
        switch phase {
        case .focusing, .focusPaused, .breakRunning, .breakPaused:
            true
        case .idle, .reflecting, .completed, .abandoned:
            false
        }
    }

    private func adjustDuration(byMinutes minutes: Int) {
        let updatedMinutes = min(
            max(viewModel.durationMinutes + minutes, FocusClockDialMath.minMinutes),
            FocusClockDialMath.maxMinutes
        )
        viewModel.updateDurationFromDial(
            normalizedValue: FocusClockDialMath.normalizedValue(forMinutes: updatedMinutes)
        )
    }
}

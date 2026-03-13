import CoreGraphics
import FocusSessionCore

struct CurrentSessionLayoutMetrics {
    let showsTopAccessories: Bool
    let leftColumnSpacing: CGFloat
    let leftColumnHorizontalPadding: CGFloat
    let leftColumnVerticalPadding: CGFloat
    let setupStageContentMaxWidth: CGFloat
    let setupStageSidePanelWidth: CGFloat
    let setupStageColumnSpacing: CGFloat
    let setupHeroMaxWidth: CGFloat
    let usesTwoByTwoSupportingCards: Bool
    let setupSupportingCardColumns: Int
    let setupSupportingCardMinHeight: CGFloat
    let showsSetupSupportingCopy: Bool
    let showsSetupFooterCopy: Bool
    let usesTransparentSetupContainer: Bool
    let dialSize: CGFloat
    let dialShowsCenterReadout: Bool
    let dialUsesSoftPlatter: Bool
    let dialHubDiameter: CGFloat
    let dialHandShadowRadius: CGFloat
    let intentionTitleFontSize: CGFloat
    let intentionInputFontSize: CGFloat
    let intentionInputHeight: CGFloat
    let taskSelectorMaxWidth: CGFloat
    let notesTitleFontSize: CGFloat
    let recentSectionTitleFontSize: CGFloat
    let recentSessionTitleFontSize: CGFloat
    let supportingCopyFontSize: CGFloat
    let notesBodyFontSize: CGFloat
    let timeReadoutFontSize: CGFloat
    let statusValueFontSize: CGFloat
    let statusMetaFontSize: CGFloat
    let statusActionFontSize: CGFloat
    let durationControlFontSize: CGFloat
    let noteEditorHorizontalInset: CGFloat
    let noteEditorVerticalInset: CGFloat
    let noteEditorMinHeight: CGFloat
    let historySectionMaxHeight: CGFloat
    let footerButtonSize: CGFloat
    let footerButtonIconSize: CGFloat
    let footerButtonLabelFontSize: CGFloat
    let footerRowSpacing: CGFloat

    static func make(
        widthTier: AppResponsiveWidthTier,
        isCompactHeight: Bool,
        phase: SessionPhase
    ) -> CurrentSessionLayoutMetrics {
        let isRunningPhase: Bool
        switch phase {
        case .focusing, .focusPaused, .breakRunning, .breakPaused:
            isRunningPhase = true
        case .idle, .reflecting, .completed, .abandoned:
            isRunningPhase = false
        }

        if isCompactHeight {
            switch widthTier {
            case .compact:
                return CurrentSessionLayoutMetrics(
                    showsTopAccessories: false,
                    leftColumnSpacing: isRunningPhase ? 10 : 12,
                    leftColumnHorizontalPadding: 18,
                    leftColumnVerticalPadding: 14,
                    setupStageContentMaxWidth: 620,
                    setupStageSidePanelWidth: 0,
                    setupStageColumnSpacing: 12,
                    setupHeroMaxWidth: 340,
                    usesTwoByTwoSupportingCards: false,
                    setupSupportingCardColumns: 1,
                    setupSupportingCardMinHeight: 0,
                    showsSetupSupportingCopy: false,
                    showsSetupFooterCopy: false,
                    usesTransparentSetupContainer: true,
                    dialSize: isRunningPhase ? 228 : 250,
                    dialShowsCenterReadout: false,
                    dialUsesSoftPlatter: true,
                    dialHubDiameter: 18,
                    dialHandShadowRadius: 10,
                    intentionTitleFontSize: 12,
                    intentionInputFontSize: 16,
                    intentionInputHeight: 48,
                    taskSelectorMaxWidth: 300,
                    notesTitleFontSize: 17,
                    recentSectionTitleFontSize: 14,
                    recentSessionTitleFontSize: 14,
                    supportingCopyFontSize: 13,
                    notesBodyFontSize: 13,
                    timeReadoutFontSize: isRunningPhase ? 28 : 26,
                    statusValueFontSize: 15,
                    statusMetaFontSize: 11,
                    statusActionFontSize: 12,
                    durationControlFontSize: 13,
                    noteEditorHorizontalInset: 18,
                    noteEditorVerticalInset: 16,
                    noteEditorMinHeight: 220,
                    historySectionMaxHeight: 200,
                    footerButtonSize: isRunningPhase ? 68 : 72,
                    footerButtonIconSize: 17,
                    footerButtonLabelFontSize: 12,
                    footerRowSpacing: 14
                )
            case .regular:
                break
            case .expanded:
                return CurrentSessionLayoutMetrics(
                    showsTopAccessories: false,
                    leftColumnSpacing: isRunningPhase ? 12 : 14,
                    leftColumnHorizontalPadding: 24,
                    leftColumnVerticalPadding: 16,
                    setupStageContentMaxWidth: 840,
                    setupStageSidePanelWidth: 0,
                    setupStageColumnSpacing: 14,
                    setupHeroMaxWidth: 480,
                    usesTwoByTwoSupportingCards: false,
                    setupSupportingCardColumns: 1,
                    setupSupportingCardMinHeight: 0,
                    showsSetupSupportingCopy: false,
                    showsSetupFooterCopy: false,
                    usesTransparentSetupContainer: true,
                    dialSize: isRunningPhase ? 276 : 304,
                    dialShowsCenterReadout: false,
                    dialUsesSoftPlatter: true,
                    dialHubDiameter: 18,
                    dialHandShadowRadius: 10,
                    intentionTitleFontSize: 12,
                    intentionInputFontSize: 17,
                    intentionInputHeight: 50,
                    taskSelectorMaxWidth: 380,
                    notesTitleFontSize: 18,
                    recentSectionTitleFontSize: 15,
                    recentSessionTitleFontSize: 15,
                    supportingCopyFontSize: 14,
                    notesBodyFontSize: 14,
                    timeReadoutFontSize: isRunningPhase ? 34 : 30,
                    statusValueFontSize: 16,
                    statusMetaFontSize: 11,
                    statusActionFontSize: 12,
                    durationControlFontSize: 14,
                    noteEditorHorizontalInset: 20,
                    noteEditorVerticalInset: 18,
                    noteEditorMinHeight: 280,
                    historySectionMaxHeight: 220,
                    footerButtonSize: isRunningPhase ? 74 : 78,
                    footerButtonIconSize: 18,
                    footerButtonLabelFontSize: 13,
                    footerRowSpacing: 16
                )
            }

            return CurrentSessionLayoutMetrics(
                showsTopAccessories: false,
                leftColumnSpacing: isRunningPhase ? 12 : 14,
                leftColumnHorizontalPadding: 24,
                leftColumnVerticalPadding: 16,
                setupStageContentMaxWidth: 760,
                setupStageSidePanelWidth: 0,
                setupStageColumnSpacing: 14,
                setupHeroMaxWidth: 420,
                usesTwoByTwoSupportingCards: false,
                setupSupportingCardColumns: 1,
                setupSupportingCardMinHeight: 0,
                showsSetupSupportingCopy: false,
                showsSetupFooterCopy: false,
                usesTransparentSetupContainer: true,
                dialSize: isRunningPhase ? 258 : 286,
                dialShowsCenterReadout: false,
                dialUsesSoftPlatter: true,
                dialHubDiameter: 18,
                dialHandShadowRadius: 10,
                intentionTitleFontSize: 12,
                intentionInputFontSize: 17,
                intentionInputHeight: 50,
                taskSelectorMaxWidth: 340,
                notesTitleFontSize: 18,
                recentSectionTitleFontSize: 15,
                recentSessionTitleFontSize: 15,
                supportingCopyFontSize: 14,
                notesBodyFontSize: 14,
                timeReadoutFontSize: isRunningPhase ? 32 : 28,
                statusValueFontSize: 16,
                statusMetaFontSize: 11,
                statusActionFontSize: 12,
                durationControlFontSize: 14,
                noteEditorHorizontalInset: 20,
                noteEditorVerticalInset: 18,
                noteEditorMinHeight: 260,
                historySectionMaxHeight: 220,
                footerButtonSize: isRunningPhase ? 72 : 76,
                footerButtonIconSize: 18,
                footerButtonLabelFontSize: 13,
                footerRowSpacing: 16
            )
        }

        switch widthTier {
        case .compact:
            return CurrentSessionLayoutMetrics(
                showsTopAccessories: false,
                leftColumnSpacing: isRunningPhase ? 14 : 18,
                leftColumnHorizontalPadding: 20,
                leftColumnVerticalPadding: 16,
                setupStageContentMaxWidth: 580,
                setupStageSidePanelWidth: 0,
                setupStageColumnSpacing: 16,
                setupHeroMaxWidth: 360,
                usesTwoByTwoSupportingCards: false,
                setupSupportingCardColumns: 1,
                setupSupportingCardMinHeight: 0,
                showsSetupSupportingCopy: false,
                showsSetupFooterCopy: false,
                usesTransparentSetupContainer: true,
                dialSize: isRunningPhase ? 248 : 280,
                dialShowsCenterReadout: false,
                dialUsesSoftPlatter: true,
                dialHubDiameter: 20,
                dialHandShadowRadius: 10,
                intentionTitleFontSize: 12,
                intentionInputFontSize: 17,
                intentionInputHeight: 52,
                taskSelectorMaxWidth: 320,
                notesTitleFontSize: 18,
                recentSectionTitleFontSize: 14,
                recentSessionTitleFontSize: 15,
                supportingCopyFontSize: 13,
                notesBodyFontSize: 14,
                timeReadoutFontSize: isRunningPhase ? 30 : 32,
                statusValueFontSize: 17,
                statusMetaFontSize: 11,
                statusActionFontSize: 12,
                durationControlFontSize: 14,
                noteEditorHorizontalInset: 20,
                noteEditorVerticalInset: 18,
                noteEditorMinHeight: 280,
                historySectionMaxHeight: 220,
                footerButtonSize: isRunningPhase ? 72 : 76,
                footerButtonIconSize: 18,
                footerButtonLabelFontSize: 12,
                footerRowSpacing: 16
            )
        case .regular:
            break
        case .expanded:
            return CurrentSessionLayoutMetrics(
                showsTopAccessories: false,
                leftColumnSpacing: isRunningPhase ? 16 : 20,
                leftColumnHorizontalPadding: 28,
                leftColumnVerticalPadding: 20,
                setupStageContentMaxWidth: 760,
                setupStageSidePanelWidth: 0,
                setupStageColumnSpacing: 18,
                setupHeroMaxWidth: 520,
                usesTwoByTwoSupportingCards: false,
                setupSupportingCardColumns: 1,
                setupSupportingCardMinHeight: 0,
                showsSetupSupportingCopy: false,
                showsSetupFooterCopy: false,
                usesTransparentSetupContainer: true,
                dialSize: isRunningPhase ? 304 : 344,
                dialShowsCenterReadout: false,
                dialUsesSoftPlatter: true,
                dialHubDiameter: 22,
                dialHandShadowRadius: 12,
                intentionTitleFontSize: 12,
                intentionInputFontSize: 18,
                intentionInputHeight: 54,
                taskSelectorMaxWidth: 440,
                notesTitleFontSize: 20,
                recentSectionTitleFontSize: 15,
                recentSessionTitleFontSize: 16,
                supportingCopyFontSize: 14,
                notesBodyFontSize: 15,
                timeReadoutFontSize: isRunningPhase ? 36 : 38,
                statusValueFontSize: 18,
                statusMetaFontSize: 12,
                statusActionFontSize: 13,
                durationControlFontSize: 15,
                noteEditorHorizontalInset: 22,
                noteEditorVerticalInset: 20,
                noteEditorMinHeight: 320,
                historySectionMaxHeight: 250,
                footerButtonSize: isRunningPhase ? 78 : 82,
                footerButtonIconSize: 20,
                footerButtonLabelFontSize: 13,
                footerRowSpacing: 18
            )
        }

        return CurrentSessionLayoutMetrics(
            showsTopAccessories: false,
            leftColumnSpacing: isRunningPhase ? 16 : 20,
            leftColumnHorizontalPadding: 24,
            leftColumnVerticalPadding: 18,
            setupStageContentMaxWidth: 660,
            setupStageSidePanelWidth: 0,
            setupStageColumnSpacing: 18,
            setupHeroMaxWidth: 460,
            usesTwoByTwoSupportingCards: false,
            setupSupportingCardColumns: 1,
            setupSupportingCardMinHeight: 0,
            showsSetupSupportingCopy: false,
            showsSetupFooterCopy: false,
            usesTransparentSetupContainer: true,
            dialSize: isRunningPhase ? 284 : 324,
            dialShowsCenterReadout: false,
            dialUsesSoftPlatter: true,
            dialHubDiameter: 22,
            dialHandShadowRadius: 12,
            intentionTitleFontSize: 12,
            intentionInputFontSize: 18,
            intentionInputHeight: 54,
            taskSelectorMaxWidth: 392,
            notesTitleFontSize: 20,
            recentSectionTitleFontSize: 15,
            recentSessionTitleFontSize: 16,
            supportingCopyFontSize: 14,
            notesBodyFontSize: 15,
            timeReadoutFontSize: isRunningPhase ? 34 : 36,
            statusValueFontSize: 18,
            statusMetaFontSize: 12,
            statusActionFontSize: 13,
            durationControlFontSize: 15,
            noteEditorHorizontalInset: 22,
            noteEditorVerticalInset: 20,
            noteEditorMinHeight: 320,
            historySectionMaxHeight: 250,
            footerButtonSize: isRunningPhase ? 76 : 80,
            footerButtonIconSize: 20,
            footerButtonLabelFontSize: 13,
            footerRowSpacing: 18
        )
    }
}

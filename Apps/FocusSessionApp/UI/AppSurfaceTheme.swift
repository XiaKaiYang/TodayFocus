import AppKit
import SwiftUI

enum AppSurfaceTheme {
    static let primaryTextOpacity = 0.82
    static let secondaryTextOpacity = 0.58
    static let tertiaryTextOpacity = 0.50
    static let mutedTextOpacity = 0.46
    static let accentTextOpacity = 0.88
    static let cardBorderOpacity = 0.06
    static let standardCardFillOpacity = 0.56
    static let elevatedCardFillOpacity = 0.72
    static let softCardFillOpacity = 0.74
    static let sidebarFillOpacity = 0.0
    static let sidebarSelectedFillOpacity = 0.0
    static let sidebarSelectionAccentOpacity = 0.18
    static let taskSelectorGlyphOpacity = 0.74
    static let taskSelectorWarmGlyphRed = 0.40
    static let taskSelectorWarmGlyphGreen = 0.35
    static let taskSelectorWarmGlyphBlue = 0.31
    static let taskSelectorWarmBorderRed = 0.63
    static let taskSelectorWarmBorderGreen = 0.56
    static let taskSelectorWarmBorderBlue = 0.49
    static let inputFillOpacity = 0.0
    static let inputStrokeOpacity = 0.12
    static let glassFillTopOpacity = 0.24
    static let glassFillBottomOpacity = 0.12
    static let glassStrokeOpacity = 0.10
    static let glassShadowOpacity = 0.12

    static var canvasGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.93, blue: 0.89),
                Color(red: 0.90, green: 0.93, blue: 0.97)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var primaryText: Color {
        Color.black.opacity(primaryTextOpacity)
    }

    static var secondaryText: Color {
        Color.black.opacity(secondaryTextOpacity)
    }

    static var tertiaryText: Color {
        Color.black.opacity(tertiaryTextOpacity)
    }

    static var mutedText: Color {
        Color.black.opacity(mutedTextOpacity)
    }

    static var accentText: Color {
        Color.black.opacity(accentTextOpacity)
    }

    static var outline: Color {
        Color.black.opacity(cardBorderOpacity)
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.93, green: 0.29, blue: 0.30),
                Color(red: 0.74, green: 0.22, blue: 0.23)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var sidebarSelectionAccent: Color {
        Color.black.opacity(sidebarSelectionAccentOpacity)
    }

    static var taskSelectorGlyph: Color {
        Color.black.opacity(taskSelectorGlyphOpacity)
    }

    static var taskSelectorWarmGlyph: Color {
        Color(
            red: taskSelectorWarmGlyphRed,
            green: taskSelectorWarmGlyphGreen,
            blue: taskSelectorWarmGlyphBlue
        )
    }

    static var taskSelectorWarmBorder: Color {
        Color(
            red: taskSelectorWarmBorderRed,
            green: taskSelectorWarmBorderGreen,
            blue: taskSelectorWarmBorderBlue
        )
    }

    static var taskSelectorWarmText: Color {
        taskSelectorWarmGlyph.opacity(0.88)
    }

    static var inputBorder: Color {
        Color.black.opacity(inputStrokeOpacity)
    }

    static var glassTopTint: Color {
        Color(red: 0.88, green: 0.91, blue: 0.97).opacity(glassFillTopOpacity)
    }

    static var glassBottomTint: Color {
        Color(red: 0.81, green: 0.86, blue: 0.95).opacity(glassFillBottomOpacity)
    }

    static var glassStroke: Color {
        Color.black.opacity(glassStrokeOpacity)
    }

    static var glassShadow: Color {
        Color(red: 0.56, green: 0.62, blue: 0.72).opacity(glassShadowOpacity)
    }
}

enum AppCardSurfaceStyle {
    case standard
    case elevated
    case soft
    case sidebar
    case sidebarSelected
}

struct AppCanvasBackground: View {
    var body: some View {
        AppSurfaceTheme.canvasGradient
            .ignoresSafeArea()
    }
}

struct AppCardSurface: View {
    let style: AppCardSurfaceStyle
    let cornerRadius: CGFloat

    init(style: AppCardSurfaceStyle, cornerRadius: CGFloat = 28) {
        self.style = style
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(fillColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
    }

    private var fillColor: Color {
        switch style {
        case .standard:
            Color.white.opacity(AppSurfaceTheme.standardCardFillOpacity)
        case .elevated:
            Color.white.opacity(AppSurfaceTheme.elevatedCardFillOpacity)
        case .soft:
            Color.white.opacity(AppSurfaceTheme.softCardFillOpacity)
        case .sidebar:
            Color.white.opacity(AppSurfaceTheme.sidebarFillOpacity)
        case .sidebarSelected:
            Color.white.opacity(AppSurfaceTheme.sidebarSelectedFillOpacity)
        }
    }

    private var borderColor: Color {
        switch style {
        case .sidebarSelected:
            Color.black.opacity(0.08)
        case .standard, .elevated, .soft, .sidebar:
            AppSurfaceTheme.outline
        }
    }
}

struct AppInputSurface: View {
    let cornerRadius: CGFloat
    let fillColor: Color
    let strokeColor: Color

    init(
        cornerRadius: CGFloat = 22,
        fillColor: Color = Color.black.opacity(AppSurfaceTheme.inputFillOpacity),
        strokeColor: Color = AppSurfaceTheme.inputBorder
    ) {
        self.cornerRadius = cornerRadius
        self.fillColor = fillColor
        self.strokeColor = strokeColor
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(fillColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            )
    }
}

struct AppGlassRoundedSurface: View {
    let cornerRadius: CGFloat
    let tint: Color?

    init(cornerRadius: CGFloat = 20, tint: Color? = nil) {
        self.cornerRadius = cornerRadius
        self.tint = tint
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        AppSurfaceTheme.glassTopTint,
                        AppSurfaceTheme.glassBottomTint
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.52)
            )
            .overlay {
                if let tint {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tint.opacity(0.16))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppSurfaceTheme.glassStroke, lineWidth: 1)
            )
            .shadow(color: AppSurfaceTheme.glassShadow, radius: 14, y: 8)
    }
}

struct AppGlassCapsuleSurface: View {
    let tint: Color?

    init(tint: Color? = nil) {
        self.tint = tint
    }

    var body: some View {
        Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        AppSurfaceTheme.glassTopTint,
                        AppSurfaceTheme.glassBottomTint
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.52)
            )
            .overlay {
                if let tint {
                    Capsule(style: .continuous)
                        .fill(tint.opacity(0.16))
                }
            }
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AppSurfaceTheme.glassStroke, lineWidth: 1)
            )
            .shadow(color: AppSurfaceTheme.glassShadow, radius: 12, y: 7)
    }
}

struct AppGlassCircleSurface: View {
    let tint: Color?

    init(tint: Color? = nil) {
        self.tint = tint
    }

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        AppSurfaceTheme.glassTopTint,
                        AppSurfaceTheme.glassBottomTint
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Circle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.52)
            )
            .overlay {
                if let tint {
                    Circle()
                        .fill(tint.opacity(0.16))
                }
            }
            .overlay(
                Circle()
                    .stroke(AppSurfaceTheme.glassStroke, lineWidth: 1)
            )
            .shadow(color: AppSurfaceTheme.glassShadow, radius: 12, y: 8)
    }
}

struct AppAccentButtonStyle: ButtonStyle {
    let cornerRadius: CGFloat

    init(cornerRadius: CGFloat = 16) {
        self.cornerRadius = cornerRadius
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(AppSurfaceTheme.accentText)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppSurfaceTheme.accentGradient)
            )
            .shadow(
                color: Color(red: 0.90, green: 0.29, blue: 0.30).opacity(configuration.isPressed ? 0.18 : 0.28),
                radius: 12,
                y: 8
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct AppSegmentedControl<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let tint: Color?
    let title: (Option) -> String
    let fontSize: CGFloat
    let verticalPadding: CGFloat
    let itemCornerRadius: CGFloat
    let itemSpacing: CGFloat
    let containerPadding: CGFloat
    let containerCornerRadius: CGFloat

    init(
        options: [Option],
        selection: Binding<Option>,
        tint: Color? = nil,
        fontSize: CGFloat = 15,
        verticalPadding: CGFloat = 11,
        itemCornerRadius: CGFloat = 14,
        itemSpacing: CGFloat = 8,
        containerPadding: CGFloat = 6,
        containerCornerRadius: CGFloat = 18,
        title: @escaping (Option) -> String
    ) {
        self.options = options
        _selection = selection
        self.tint = tint
        self.fontSize = fontSize
        self.verticalPadding = verticalPadding
        self.itemCornerRadius = itemCornerRadius
        self.itemSpacing = itemSpacing
        self.containerPadding = containerPadding
        self.containerCornerRadius = containerCornerRadius
        self.title = title
    }

    var body: some View {
        HStack(spacing: itemSpacing) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection

                Button {
                    selection = option
                } label: {
                    Text(title(option))
                        .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? AppSurfaceTheme.primaryText : AppSurfaceTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, verticalPadding)
                        .background(
                            Group {
                                if isSelected {
                                    AppGlassRoundedSurface(cornerRadius: itemCornerRadius, tint: tint)
                                } else {
                                    RoundedRectangle(cornerRadius: itemCornerRadius, style: .continuous)
                                        .fill(Color.clear)
                                }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: itemCornerRadius, style: .continuous)
                                .stroke(
                                    isSelected ? Color.clear : AppSurfaceTheme.outline.opacity(0.9),
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(containerPadding)
        .background(AppInputSurface(cornerRadius: containerCornerRadius))
    }
}

enum DashboardTimeNavigatorMetrics {
    static let outerPadding: CGFloat = 14
    static let sectionSpacing: CGFloat = 12
    static let rowSpacing: CGFloat = 8
    static let segmentedFontSize: CGFloat = 13
    static let segmentedVerticalPadding: CGFloat = 8
    static let segmentedItemCornerRadius: CGFloat = 12
    static let segmentedItemSpacing: CGFloat = 6
    static let segmentedContainerPadding: CGFloat = 4
    static let segmentedContainerCornerRadius: CGFloat = 14
    static let navigatorButtonSize: CGFloat = 38
    static let navigatorButtonCornerRadius: CGFloat = 14
    static let navigatorButtonFontSize: CGFloat = 12
    static let titleFontSize: CGFloat = 18
    static let titleGlyphFontSize: CGFloat = 10
    static let titleHorizontalPadding: CGFloat = 12
    static let titleVerticalPadding: CGFloat = 10
    static let titleCornerRadius: CGFloat = 14
    static let scopeTabSpacing: CGFloat = 18
    static let scopeTabFontSize: CGFloat = 16
    static let scopeTabIndicatorWidth: CGFloat = 22
    static let scopeTabIndicatorHeight: CGFloat = 2
    static let scopeTabVerticalPadding: CGFloat = 2
    static let dayGridSpacing: CGFloat = 8
    static let dayWeekdayFontSize: CGFloat = 9
    static let dayNumberFontSize: CGFloat = 14
    static let dayIndicatorSize: CGFloat = 6
    static let dayCardHeight: CGFloat = 60
    static let dayCardVerticalPadding: CGFloat = 5
    static let dayCardCornerRadius: CGFloat = 14
    static let scopeCardSpacing: CGFloat = 10
    static let scopeCardTopFontSize: CGFloat = 11
    static let scopeCardBottomFontSize: CGFloat = 13
    static let scopeCardMinimumHeight: CGFloat = 52
    static let scopeCardHorizontalPadding: CGFloat = 12
    static let scopeCardVerticalPadding: CGFloat = 9
    static let scopeCardCornerRadius: CGFloat = 14
    static let scopeCardMinimumWidth: CGFloat = 120
    static let scopeCardPreferredWidth: CGFloat = 150
    static let railHeight: CGFloat = 76
    static let outerCornerRadius: CGFloat = 22
}

struct AppDropdownOption<Value: Hashable>: Identifiable, Hashable {
    let value: Value
    let title: String
    let subtitle: String?

    var id: Value { value }

    init(value: Value, title: String, subtitle: String? = nil) {
        self.value = value
        self.title = title
        self.subtitle = subtitle
    }
}

struct AppDropdownField<Value: Hashable>: View {
    let selection: Value?
    let selectedTitle: String
    let options: [AppDropdownOption<Value>]
    let isInteractive: Bool
    let height: CGFloat
    let cornerRadius: CGFloat
    let fillColor: Color
    let strokeColor: Color
    let textColor: Color
    let glyphColor: Color
    let subtitleColor: Color
    let popoverTint: Color?
    let onSelect: (Value) -> Void

    @State private var isPresented = false

    init(
        selection: Value?,
        selectedTitle: String,
        options: [AppDropdownOption<Value>],
        isInteractive: Bool = true,
        height: CGFloat = 48,
        cornerRadius: CGFloat = 18,
        fillColor: Color = Color.clear,
        strokeColor: Color = AppSurfaceTheme.inputBorder,
        textColor: Color = AppSurfaceTheme.primaryText,
        glyphColor: Color = AppSurfaceTheme.secondaryText,
        subtitleColor: Color = AppSurfaceTheme.secondaryText,
        popoverTint: Color? = nil,
        onSelect: @escaping (Value) -> Void
    ) {
        self.selection = selection
        self.selectedTitle = selectedTitle
        self.options = options
        self.isInteractive = isInteractive
        self.height = height
        self.cornerRadius = cornerRadius
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.textColor = textColor
        self.glyphColor = glyphColor
        self.subtitleColor = subtitleColor
        self.popoverTint = popoverTint
        self.onSelect = onSelect
    }

    var body: some View {
        Button {
            guard isInteractive, !options.isEmpty else { return }
            isPresented.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(glyphColor)

                Text(selectedTitle)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 0)

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(glyphColor)
                    .opacity(options.isEmpty ? 0.68 : 1)
            }
            .padding(.horizontal, 16)
            .frame(height: height)
            .background(
                AppInputSurface(
                    cornerRadius: cornerRadius,
                    fillColor: fillColor,
                    strokeColor: strokeColor
                )
            )
        }
        .buttonStyle(.plain)
        .popover(
            isPresented: $isPresented,
            attachmentAnchor: .rect(.bounds),
            arrowEdge: .bottom
        ) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(options) { option in
                    dropdownOptionRow(option)
                }
            }
            .padding(12)
            .frame(minWidth: 280, maxWidth: 320, alignment: .leading)
            .background(
                AppGlassRoundedSurface(cornerRadius: 22, tint: popoverTint)
            )
            .padding(8)
        }
    }

    private func dropdownOptionRow(_ option: AppDropdownOption<Value>) -> some View {
        let isSelected = option.value == selection

        return Button {
            onSelect(option.value)
            isPresented = false
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: option.subtitle == nil ? 0 : 3) {
                    Text(option.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(textColor)

                    if let subtitle = option.subtitle {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(subtitleColor)
                    }
                }

                Spacer(minLength: 12)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(glyphColor)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? fillColor.opacity(0.95) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? strokeColor.opacity(0.85) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct AppGlassButtonStyle: ButtonStyle {
    let cornerRadius: CGFloat
    let tint: Color?
    let foregroundColor: Color

    init(
        cornerRadius: CGFloat = 16,
        tint: Color? = nil,
        foregroundColor: Color = AppSurfaceTheme.primaryText
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.foregroundColor = foregroundColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(foregroundColor.opacity(configuration.isPressed ? 0.76 : 1))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                AppGlassRoundedSurface(cornerRadius: cornerRadius, tint: tint)
                    .opacity(configuration.isPressed ? 0.84 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct DashboardTimeNavigator: View {
    let selectedScope: DashboardTimeScope
    let referenceTitle: String
    let timeStrip: DashboardTimeStrip
    let onSelectScope: @MainActor (DashboardTimeScope) -> Void
    let onMoveBackward: @MainActor () -> Void
    let onMoveForward: @MainActor () -> Void
    let onSelectDate: @MainActor (Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DashboardTimeNavigatorMetrics.sectionSpacing) {
            scopeHeaderTabs

            HStack(spacing: DashboardTimeNavigatorMetrics.rowSpacing) {
                navigatorButton(systemName: "chevron.left", action: onMoveBackward)

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    Text(referenceTitle)
                        .font(.system(size: DashboardTimeNavigatorMetrics.titleFontSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.primaryText)
                        .lineLimit(1)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: DashboardTimeNavigatorMetrics.titleGlyphFontSize, weight: .semibold))
                        .foregroundStyle(AppSurfaceTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Spacer(minLength: 0)

                navigatorButton(systemName: "chevron.right", action: onMoveForward)
            }

            stripContent
        }
    }

    private var scopeHeaderTabs: some View {
        HStack(spacing: DashboardTimeNavigatorMetrics.scopeTabSpacing) {
            ForEach(DashboardTimeScope.allCases, id: \.self) { scope in
                let isSelected = scope == selectedScope

                Button {
                    onSelectScope(scope)
                } label: {
                    VStack(spacing: 6) {
                        Text(scope.title)
                            .font(
                                .system(
                                    size: DashboardTimeNavigatorMetrics.scopeTabFontSize,
                                    weight: isSelected ? .bold : .semibold,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(
                                isSelected
                                    ? AppSurfaceTheme.primaryText
                                    : AppSurfaceTheme.secondaryText
                            )

                        Capsule(style: .continuous)
                            .fill(Color(red: 0.90, green: 0.33, blue: 0.35))
                            .frame(
                                width: DashboardTimeNavigatorMetrics.scopeTabIndicatorWidth,
                                height: DashboardTimeNavigatorMetrics.scopeTabIndicatorHeight
                            )
                            .opacity(isSelected ? 0.95 : 0)
                    }
                    .padding(.vertical, DashboardTimeNavigatorMetrics.scopeTabVerticalPadding)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var stripContent: some View {
        switch timeStrip {
        case let .days(days):
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: DashboardTimeNavigatorMetrics.dayGridSpacing),
                    count: 7
                ),
                spacing: DashboardTimeNavigatorMetrics.dayGridSpacing
            ) {
                ForEach(days) { item in
                    Button {
                        onSelectDate(item.date)
                    } label: {
                        VStack(spacing: 4) {
                            Text(item.weekdayText)
                                .font(.system(size: DashboardTimeNavigatorMetrics.dayWeekdayFontSize, weight: .bold, design: .rounded))
                                .foregroundStyle(item.isSelected ? AppSurfaceTheme.primaryText : AppSurfaceTheme.secondaryText)

                            Text(item.dayText)
                                .font(.system(size: DashboardTimeNavigatorMetrics.dayNumberFontSize, weight: .bold, design: .rounded))
                                .foregroundStyle(item.isSelected ? AppSurfaceTheme.primaryText : AppSurfaceTheme.secondaryText)

                            Circle()
                                .fill(Color(red: 0.90, green: 0.33, blue: 0.35))
                                .frame(
                                    width: DashboardTimeNavigatorMetrics.dayIndicatorSize,
                                    height: DashboardTimeNavigatorMetrics.dayIndicatorSize
                                )
                                .opacity(item.isToday ? 1 : 0)
                        }
                        .frame(maxWidth: .infinity, minHeight: DashboardTimeNavigatorMetrics.dayCardHeight)
                        .padding(.vertical, DashboardTimeNavigatorMetrics.dayCardVerticalPadding)
                        .background(weekdayBackground(for: item))
                    }
                    .buttonStyle(.plain)
                }
            }
        case let .weeks(weeks):
            stripRail { cardWidth in
                ForEach(weeks) { item in
                    Button {
                        onSelectDate(item.startDate)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.topText)
                                .font(.system(size: DashboardTimeNavigatorMetrics.scopeCardTopFontSize, weight: .medium, design: .rounded))
                                .foregroundStyle(item.isSelected ? AppSurfaceTheme.primaryText : AppSurfaceTheme.secondaryText)

                            Text(item.bottomText)
                                .font(.system(size: DashboardTimeNavigatorMetrics.scopeCardBottomFontSize, weight: .bold, design: .rounded))
                                .foregroundStyle(item.isSelected ? AppSurfaceTheme.primaryText : AppSurfaceTheme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, minHeight: DashboardTimeNavigatorMetrics.scopeCardMinimumHeight, alignment: .leading)
                        .padding(.horizontal, DashboardTimeNavigatorMetrics.scopeCardHorizontalPadding)
                        .padding(.vertical, DashboardTimeNavigatorMetrics.scopeCardVerticalPadding)
                        .background(scopeCardBackground(isSelected: item.isSelected))
                    }
                    .frame(width: cardWidth)
                    .buttonStyle(.plain)
                }
            }
        case let .months(months):
            stripRail { cardWidth in
                ForEach(months) { item in
                    Button {
                        onSelectDate(item.date)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.yearText)
                                .font(.system(size: DashboardTimeNavigatorMetrics.scopeCardTopFontSize, weight: .medium, design: .rounded))
                                .foregroundStyle(item.isSelected ? AppSurfaceTheme.primaryText : AppSurfaceTheme.secondaryText)

                            Text(item.monthText)
                                .font(.system(size: DashboardTimeNavigatorMetrics.scopeCardBottomFontSize, weight: .bold, design: .rounded))
                                .foregroundStyle(item.isSelected ? AppSurfaceTheme.primaryText : AppSurfaceTheme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, minHeight: DashboardTimeNavigatorMetrics.scopeCardMinimumHeight, alignment: .leading)
                        .padding(.horizontal, DashboardTimeNavigatorMetrics.scopeCardHorizontalPadding)
                        .padding(.vertical, DashboardTimeNavigatorMetrics.scopeCardVerticalPadding)
                        .background(scopeCardBackground(isSelected: item.isSelected))
                    }
                    .frame(width: cardWidth)
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func navigatorButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: DashboardTimeNavigatorMetrics.navigatorButtonFontSize, weight: .bold))
                .foregroundStyle(AppSurfaceTheme.primaryText.opacity(0.78))
                .frame(
                    width: DashboardTimeNavigatorMetrics.navigatorButtonSize,
                    height: DashboardTimeNavigatorMetrics.navigatorButtonSize
                )
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func weekdayBackground(for item: DashboardWeekdayItem) -> some View {
        if item.isSelected {
            AppGlassRoundedSurface(
                cornerRadius: DashboardTimeNavigatorMetrics.dayCardCornerRadius,
                tint: Color(red: 0.90, green: 0.33, blue: 0.35)
            )
        } else {
            AppCardSurface(style: .elevated, cornerRadius: DashboardTimeNavigatorMetrics.dayCardCornerRadius)
        }
    }

    @ViewBuilder
    private func scopeCardBackground(isSelected: Bool) -> some View {
        if isSelected {
            AppGlassRoundedSurface(
                cornerRadius: DashboardTimeNavigatorMetrics.scopeCardCornerRadius,
                tint: Color(red: 0.90, green: 0.33, blue: 0.35)
            )
        } else {
            AppCardSurface(style: .elevated, cornerRadius: DashboardTimeNavigatorMetrics.scopeCardCornerRadius)
        }
    }

    private func stripRail<Content: View>(
        @ViewBuilder content: @escaping (_ cardWidth: CGFloat) -> Content
    ) -> some View {
        GeometryReader { geometry in
            let totalSpacing = DashboardTimeNavigatorMetrics.scopeCardSpacing * 4
            let fittedWidth = (geometry.size.width - totalSpacing) / 5
            let cardWidth = min(
                DashboardTimeNavigatorMetrics.scopeCardPreferredWidth,
                max(DashboardTimeNavigatorMetrics.scopeCardMinimumWidth, fittedWidth)
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DashboardTimeNavigatorMetrics.scopeCardSpacing) {
                    content(cardWidth)
                }
                .frame(minWidth: geometry.size.width, alignment: .center)
            }
        }
        .frame(height: DashboardTimeNavigatorMetrics.railHeight)
    }
}

struct AppPromptedTextField: View {
    let prompt: String
    @Binding var text: String
    let axis: Axis
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat

    init(
        _ prompt: String,
        text: Binding<String>,
        axis: Axis = .horizontal,
        cornerRadius: CGFloat = 22,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 12
    ) {
        self.prompt = prompt
        _text = text
        self.axis = axis
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }

    var body: some View {
        ZStack(alignment: axis == .vertical ? .topLeading : .leading) {
            if text.isEmpty {
                Text(prompt)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.mutedText)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                    .allowsHitTesting(false)
            }

            TextField("", text: $text, axis: axis)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)
                .tint(AppSurfaceTheme.primaryText)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
        }
        .background(AppInputSurface(cornerRadius: cornerRadius))
    }
}

struct AppPromptedTextEditor: View {
    let prompt: String
    @Binding var text: String
    let fontSize: CGFloat
    let cornerRadius: CGFloat
    let horizontalInset: CGFloat
    let verticalInset: CGFloat
    var focus: Binding<Bool>? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppPromptedTextEditorRepresentable(
                text: $text,
                fontSize: fontSize,
                horizontalInset: horizontalInset,
                verticalInset: verticalInset,
                focus: focus
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(prompt)
                    .font(.system(size: fontSize, weight: .medium, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.mutedText)
                    .padding(.horizontal, horizontalInset)
                    .padding(.vertical, verticalInset)
                    .allowsHitTesting(false)
            }
        }
        .background(AppInputSurface(cornerRadius: cornerRadius))
    }
}

private final class AppFixedInkTextView: NSTextView {
    var fixedTypingAttributes: [NSAttributedString.Key: Any] = [:] {
        didSet {
            super.typingAttributes = fixedTypingAttributes
            applyFixedInkToExistingText()
        }
    }

    var fixedTextColor: NSColor = .black {
        didSet {
            super.textColor = fixedTextColor
            applyFixedInkToExistingText()
        }
    }

    func applyFixedInkToExistingText() {
        guard let textStorage, textStorage.length > 0 else { return }

        textStorage.addAttributes(
            fixedTypingAttributes,
            range: NSRange(location: 0, length: textStorage.length)
        )
    }

    override func didChangeText() {
        super.didChangeText()
        applyFixedInkToExistingText()
        super.typingAttributes = fixedTypingAttributes
    }

    override func setSelectedRange(
        _ charRange: NSRange,
        affinity: NSSelectionAffinity,
        stillSelecting flag: Bool
    ) {
        super.setSelectedRange(charRange, affinity: affinity, stillSelecting: flag)
        super.typingAttributes = fixedTypingAttributes
    }
}

private struct AppPromptedTextEditorRepresentable: NSViewRepresentable {
    @Binding var text: String
    let fontSize: CGFloat
    let horizontalInset: CGFloat
    let verticalInset: CGFloat
    let focus: Binding<Bool>?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay

        let textView = AppFixedInkTextView()
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.minSize = .zero
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainerInset = NSSize(width: horizontalInset, height: verticalInset)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.lineFragmentPadding = 0
        textView.string = text
        textView.font = editorFont
        textView.fixedTextColor = editorTextColor
        textView.fixedTypingAttributes = typingAttributes
        textView.insertionPointColor = .systemBlue

        scrollView.documentView = textView
        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self

        guard let textView = scrollView.documentView as? AppFixedInkTextView else { return }

        if textView.string != text {
            textView.string = text
        }

        textView.font = editorFont
        textView.fixedTextColor = editorTextColor
        textView.fixedTypingAttributes = typingAttributes
        textView.textContainerInset = NSSize(width: horizontalInset, height: verticalInset)
        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.lineFragmentPadding = 0
        textView.applyFixedInkToExistingText()

        if let focus {
            let isFocused = focus.wrappedValue
            let isFirstResponder = textView.window?.firstResponder === textView

            if isFocused && !isFirstResponder {
                textView.window?.makeFirstResponder(textView)
            }
        }
    }

    private var editorFont: NSFont {
        let base = NSFont.systemFont(ofSize: fontSize, weight: .medium)
        if let descriptor = base.fontDescriptor.withDesign(.rounded),
           let rounded = NSFont(descriptor: descriptor, size: fontSize) {
            return rounded
        }
        return base
    }

    private var editorTextColor: NSColor {
        NSColor(
            calibratedRed: 0,
            green: 0,
            blue: 0,
            alpha: AppSurfaceTheme.primaryTextOpacity
        )
    }

    private var typingAttributes: [NSAttributedString.Key: Any] {
        [
            .font: editorFont,
            .foregroundColor: editorTextColor
        ]
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: AppPromptedTextEditorRepresentable
        weak var textView: NSTextView?

        init(_ parent: AppPromptedTextEditorRepresentable) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            parent.text = textView?.string ?? ""
        }

        func textDidBeginEditing(_ notification: Notification) {
            parent.focus?.wrappedValue = true
        }

        func textDidEndEditing(_ notification: Notification) {
            parent.focus?.wrappedValue = false
        }
    }
}

struct AppInlineStepper: View {
    let title: String
    let valueText: String
    let decrementDisabled: Bool
    let incrementDisabled: Bool
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppSurfaceTheme.primaryText)

            HStack(spacing: 12) {
                appStepperButton(systemImage: "minus", isDisabled: decrementDisabled, action: onDecrement)
                Text(valueText)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.primaryText)
                    .frame(minWidth: 88)
                appStepperButton(systemImage: "plus", isDisabled: incrementDisabled, action: onIncrement)
            }
        }
    }

    private func appStepperButton(
        systemImage: String,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isDisabled ? AppSurfaceTheme.mutedText : AppSurfaceTheme.primaryText)
                .frame(width: 34, height: 34)
                .background(
                    AppGlassCircleSurface(
                        tint: isDisabled ? Color.black.opacity(0.02) : Color(red: 0.58, green: 0.68, blue: 0.84)
                    )
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

extension View {
    func appInputChrome(
        cornerRadius: CGFloat = 22,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 12
    ) -> some View {
        self
            .textFieldStyle(.plain)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(AppInputSurface(cornerRadius: cornerRadius))
    }
}

import SwiftUI

struct WhiteNoiseDashboardView: View {
    @ObservedObject var viewModel: WhiteNoiseViewModel

    var body: some View {
        ZStack {
            AppCanvasBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    WhiteNoiseBackgroundSoundCard(viewModel: viewModel)
                    WhiteNoiseSoundCard(
                        title: "Session sound",
                        selectedTitle: viewModel.displayTitle(for: viewModel.preferences.sessionSoundName),
                        options: viewModel.sessionSoundOptions,
                        volume: viewModel.preferences.sessionSoundVolume,
                        onVolumeChange: { volume in
                            viewModel.updateSessionSoundVolume(volume)
                        },
                        onSelect: { assetName in
                            viewModel.updateSessionSoundName(assetName)
                        }
                    )
                    WhiteNoiseSoundCard(
                        title: "Session end sound",
                        selectedTitle: viewModel.displayTitle(for: viewModel.preferences.sessionEndSoundName),
                        options: viewModel.sessionEndSoundOptions,
                        volume: viewModel.preferences.sessionEndSoundVolume,
                        onVolumeChange: { volume in
                            viewModel.updateSessionEndSoundVolume(volume)
                        },
                        onSelect: { assetName in
                            viewModel.updateSessionEndSoundName(assetName)
                        }
                    )
                    WhiteNoiseSoundCard(
                        title: "Break sound",
                        selectedTitle: viewModel.displayTitle(for: viewModel.preferences.breakSoundName),
                        options: viewModel.breakSoundOptions,
                        volume: viewModel.preferences.breakSoundVolume,
                        onVolumeChange: { volume in
                            viewModel.updateBreakSoundVolume(volume)
                        },
                        onSelect: { assetName in
                            viewModel.updateBreakSoundName(assetName)
                        }
                    )
                    WhiteNoiseSoundCard(
                        title: "Break end sound",
                        selectedTitle: viewModel.displayTitle(for: viewModel.preferences.breakEndSoundName),
                        options: viewModel.breakEndSoundOptions,
                        volume: viewModel.preferences.breakEndSoundVolume,
                        onVolumeChange: { volume in
                            viewModel.updateBreakEndSoundVolume(volume)
                        },
                        onSelect: { assetName in
                            viewModel.updateBreakEndSoundName(assetName)
                        }
                    )
                }
                .padding(28)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("White Noise")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            Text("Control background sound, session sound, session end sound, break sound, and break end sound from one dedicated workspace.")
                .font(.title3)
                .foregroundStyle(AppSurfaceTheme.secondaryText)

            Text("Suggested starting points include Clock Ticking, Ocean Waves, and Gong.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.secondaryText)
        }
    }
}

private struct WhiteNoiseBackgroundSoundCard: View {
    @ObservedObject var viewModel: WhiteNoiseViewModel

    var body: some View {
        WhiteNoiseCardSurface {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 16) {
                    Text("Background sound")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.primaryText)

                    Spacer(minLength: 12)

                    Toggle(
                        "",
                        isOn: Binding(
                            get: { viewModel.preferences.backgroundSoundEnabled },
                            set: { isEnabled in
                                viewModel.setBackgroundSoundEnabled(isEnabled)
                            }
                        )
                    )
                    .labelsHidden()
                    .toggleStyle(.switch)
                }

                Text("Important: Background sound keeps the app ready to continue playback behavior while you move between sections. Turn it on when you want the selected focus ambience to follow the session lifecycle.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct WhiteNoiseSoundCard: View {
    let title: String
    let selectedTitle: String
    let options: [AppDropdownOption<String>]
    let volume: Double
    let onVolumeChange: (Double) -> Void
    let onSelect: (String) -> Void

    var body: some View {
        WhiteNoiseCardSurface {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 20) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.primaryText)

                    Spacer(minLength: 12)

                    AppDropdownField(
                        selection: options.first(where: { $0.title == selectedTitle })?.value,
                        selectedTitle: selectedTitle,
                        options: options,
                        height: 44,
                        cornerRadius: 18,
                        fillColor: AppSurfaceTheme.taskSelectorWarmBorder.opacity(0.035),
                        strokeColor: AppSurfaceTheme.taskSelectorWarmBorder.opacity(0.40),
                        textColor: AppSurfaceTheme.primaryText,
                        glyphColor: AppSurfaceTheme.taskSelectorWarmGlyph,
                        subtitleColor: AppSurfaceTheme.secondaryText,
                        popoverTint: Color(red: 0.76, green: 0.68, blue: 0.61)
                    ) { assetName in
                        onSelect(assetName)
                    }
                    .frame(width: 280)
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Volume")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.primaryText)

                    Slider(
                        value: Binding(
                            get: { volume },
                            set: { updatedVolume in
                                onVolumeChange(updatedVolume)
                            }
                        ),
                        in: 0 ... 1
                    )
                    .tint(Color(red: 0.86, green: 0.35, blue: 0.35))
                }
            }
        }
    }
}

private struct WhiteNoiseCardSurface<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(24)
            .background(AppCardSurface(style: .standard, cornerRadius: 28))
    }
}

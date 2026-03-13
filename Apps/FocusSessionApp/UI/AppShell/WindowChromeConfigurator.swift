import AppKit
import SwiftUI

struct WindowChromeSettings {
    let titleVisibility: NSWindow.TitleVisibility
    let titlebarAppearsTransparent: Bool
    let isMovableByWindowBackground: Bool
    let backgroundColor: NSColor
    let isOpaque: Bool

    // Opaque fallback prevents other apps from showing through during animated view transitions.
    private static let canvasFallbackBackgroundColor = NSColor(
        red: 0.93,
        green: 0.93,
        blue: 0.92,
        alpha: 1.0
    )

    static let `default` = WindowChromeSettings(
        titleVisibility: .hidden,
        titlebarAppearsTransparent: true,
        isMovableByWindowBackground: false,
        backgroundColor: canvasFallbackBackgroundColor,
        isOpaque: true
    )
}

struct WindowChromeConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            configure(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(nsView)
        }
    }

    private func configure(_ nsView: NSView) {
        guard let window = nsView.window else {
            return
        }

        let settings = WindowChromeSettings.default
        window.titleVisibility = settings.titleVisibility
        window.titlebarAppearsTransparent = settings.titlebarAppearsTransparent
        window.isMovableByWindowBackground = settings.isMovableByWindowBackground
        window.backgroundColor = settings.backgroundColor
        window.isOpaque = settings.isOpaque
        if #unavailable(macOS 15.0) {
            window.toolbar?.showsBaselineSeparator = false
        }
    }
}

import AppKit
import SwiftUI

enum AppMenuTitleController {
    static let activeTaskTitleColor = NSColor(
        calibratedRed: 0.82,
        green: 0.67,
        blue: 0.21,
        alpha: 1
    )

    @MainActor
    static func synchronize(
        title: String,
        highlightsActiveTask: Bool,
        in menu: NSMenu?
    ) {
        guard let firstItem = menu?.items.first else {
            return
        }

        if firstItem.title != title {
            firstItem.title = title
        }

        if highlightsActiveTask {
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: activeTaskTitleColor
            ]
            let attributedTitle = NSAttributedString(
                string: title,
                attributes: attributes
            )
            if firstItem.attributedTitle != attributedTitle {
                firstItem.attributedTitle = attributedTitle
            }
        } else if firstItem.attributedTitle != nil {
            firstItem.attributedTitle = nil
        }
    }

    @MainActor
    static func synchronize(title: String, highlightsActiveTask: Bool) {
        synchronize(
            title: title,
            highlightsActiveTask: highlightsActiveTask,
            in: NSApp.mainMenu
        )
    }
}

struct AppMenuTitleSynchronizer: NSViewRepresentable {
    let title: String
    let highlightsActiveTask: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            AppMenuTitleController.synchronize(
                title: title,
                highlightsActiveTask: highlightsActiveTask
            )
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            AppMenuTitleController.synchronize(
                title: title,
                highlightsActiveTask: highlightsActiveTask
            )
        }
    }
}

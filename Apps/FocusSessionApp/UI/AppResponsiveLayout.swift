import CoreGraphics
import SwiftUI

enum AppResponsiveWidthTier: Equatable {
    case compact
    case regular
    case expanded

    static func shell(for width: CGFloat) -> AppResponsiveWidthTier {
        classify(width, compactMax: 980, regularMax: 1440)
    }

    static func detail(for width: CGFloat) -> AppResponsiveWidthTier {
        classify(width, compactMax: 820, regularMax: 1280)
    }

    private static func classify(
        _ width: CGFloat,
        compactMax: CGFloat,
        regularMax: CGFloat
    ) -> AppResponsiveWidthTier {
        if width < compactMax {
            return .compact
        }

        if width < regularMax {
            return .regular
        }

        return .expanded
    }
}

enum DetailDashboardLayoutMetrics {
    static func contentInsets(for widthTier: AppResponsiveWidthTier) -> EdgeInsets {
        switch widthTier {
        case .compact:
            return EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        case .regular, .expanded:
            return EdgeInsets(top: 28, leading: 32, bottom: 36, trailing: 32)
        }
    }
}

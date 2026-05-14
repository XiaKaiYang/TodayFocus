import Foundation
#if os(macOS)
import CoreGraphics
#endif

protocol ScreenCapturePermissionServiceProtocol: Sendable {
    func hasPermission() -> Bool
}

struct ScreenCapturePermissionService: ScreenCapturePermissionServiceProtocol, Sendable {
    func hasPermission() -> Bool {
        #if os(macOS)
        return CGPreflightScreenCaptureAccess()
        #else
        return false
        #endif
    }
}

struct StubScreenCapturePermissionService: ScreenCapturePermissionServiceProtocol, Sendable {
    let permitted: Bool
    init(permitted: Bool = true) { self.permitted = permitted }
    func hasPermission() -> Bool { permitted }
}

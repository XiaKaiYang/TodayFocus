import Foundation

enum CameraPermissionState: Equatable, Sendable {
    case notDetermined, authorized, denied
}

enum ScreenRecordingPermissionState: Equatable, Sendable {
    case notDetermined, authorized, denied
}

enum SupervisionEligibility: Equatable, Sendable {
    case eligible
    case ineligible(reasons: [IneligibilityReason])

    enum IneligibilityReason: String, Equatable, Sendable {
        case notSignedIn
        case cameraPermissionDenied
        case screenRecordingPermissionDenied
    }
}

struct SupervisionPermissionSnapshot: Equatable, Sendable {
    var isSignedIn: Bool
    var cameraPermission: CameraPermissionState
    var screenRecordingPermission: ScreenRecordingPermissionState

    var eligibility: SupervisionEligibility {
        var reasons: [SupervisionEligibility.IneligibilityReason] = []
        if !isSignedIn { reasons.append(.notSignedIn) }
        if cameraPermission == .denied { reasons.append(.cameraPermissionDenied) }
        if screenRecordingPermission == .denied { reasons.append(.screenRecordingPermissionDenied) }
        return reasons.isEmpty ? .eligible : .ineligible(reasons: reasons)
    }
}

import AVFoundation
import Foundation
#if os(macOS)
import CoreGraphics
#endif

@MainActor
protocol SupervisionCoordinatorProtocol: AnyObject {
    var permissionSnapshot: SupervisionPermissionSnapshot { get }
    var eligibility: SupervisionEligibility { get }
    var currentStateSnapshot: SupervisionStateSnapshot? { get }
    var seatMonitor: (any SeatMonitorProtocol)? { get }
    func checkPermissions() async
    func startSupervision(sessionID: String, roomID: String, userID: String)
    func stopSupervision()
}

@MainActor
final class SupervisionCoordinator: ObservableObject, SupervisionCoordinatorProtocol {
    @Published private(set) var permissionSnapshot = SupervisionPermissionSnapshot(
        isSignedIn: false,
        cameraPermission: .notDetermined,
        screenRecordingPermission: .notDetermined
    )
    @Published private(set) var currentStateSnapshot: SupervisionStateSnapshot?
    private(set) var seatMonitor: (any SeatMonitorProtocol)?

    var eligibility: SupervisionEligibility { permissionSnapshot.eligibility }

    private let accountViewModel: AccountViewModel

    init(accountViewModel: AccountViewModel) {
        self.accountViewModel = accountViewModel
    }

    func checkPermissions() async {
        let isSignedIn = accountViewModel.isSignedIn
        let cameraStatus = await checkCameraPermission()
        let screenStatus = checkScreenRecordingPermission()
        permissionSnapshot = SupervisionPermissionSnapshot(
            isSignedIn: isSignedIn,
            cameraPermission: cameraStatus,
            screenRecordingPermission: screenStatus
        )
    }

    func startSupervision(sessionID: String, roomID: String, userID: String) {
        currentStateSnapshot = SupervisionStateSnapshot(sessionID: sessionID, roomID: roomID, userID: userID)
        let monitor = SeatMonitor(pipeline: StubSeatMonitorFramePipeline())
        monitor.start()
        seatMonitor = monitor
    }

    func stopSupervision() {
        seatMonitor?.stop()
        seatMonitor = nil
        currentStateSnapshot = nil
    }

    private func checkCameraPermission() async -> CameraPermissionState {
        #if os(macOS)
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized: return .authorized
        case .denied, .restricted: return .denied
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .authorized : .denied
        @unknown default: return .notDetermined
        }
        #else
        return .notDetermined
        #endif
    }

    private func checkScreenRecordingPermission() -> ScreenRecordingPermissionState {
        #if os(macOS)
        let hasAccess = CGPreflightScreenCaptureAccess()
        return hasAccess ? .authorized : .denied
        #else
        return .notDetermined
        #endif
    }
}

@MainActor
final class StubSupervisionCoordinator: SupervisionCoordinatorProtocol {
    var permissionSnapshot = SupervisionPermissionSnapshot(
        isSignedIn: true,
        cameraPermission: .authorized,
        screenRecordingPermission: .authorized
    )
    var currentStateSnapshot: SupervisionStateSnapshot?
    var seatMonitor: (any SeatMonitorProtocol)? = nil
    var eligibility: SupervisionEligibility { permissionSnapshot.eligibility }

    func checkPermissions() async {}

    func startSupervision(sessionID: String, roomID: String, userID: String) {
        currentStateSnapshot = SupervisionStateSnapshot(sessionID: sessionID, roomID: roomID, userID: userID)
    }

    func stopSupervision() {
        currentStateSnapshot = nil
    }
}

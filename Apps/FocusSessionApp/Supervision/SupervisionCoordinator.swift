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
    var activityMonitor: (any ActivityMonitorProtocol)? { get }
    func checkPermissions() async
    func startSupervision(sessionID: String, roomID: String, userID: String)
    func stopSupervision()
    func reportViolation(type: ViolationType) async
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
    private(set) var activityMonitor: (any ActivityMonitorProtocol)?

    var eligibility: SupervisionEligibility { permissionSnapshot.eligibility }

    private let accountViewModel: AccountViewModel
    private let supervisionRepository: any SupervisionRepositoryProtocol
    private let evidenceCaptureService: any EvidenceCaptureServiceProtocol
    private let seatMonitorFactory: @MainActor @Sendable () -> any SeatMonitorProtocol
    private let activityMonitorFactory: @MainActor @Sendable () -> any ActivityMonitorProtocol

    init(
        accountViewModel: AccountViewModel,
        supervisionRepository: any SupervisionRepositoryProtocol = SupervisionRepository(),
        evidenceCaptureService: any EvidenceCaptureServiceProtocol = EvidenceCaptureService(),
        seatMonitorFactory: @escaping @MainActor @Sendable () -> any SeatMonitorProtocol = {
            #if os(macOS)
            return SeatMonitor(pipeline: SeatMonitorFramePipeline())
            #else
            return StubSeatMonitor()
            #endif
        },
        activityMonitorFactory: @escaping @MainActor @Sendable () -> any ActivityMonitorProtocol = {
            ActivityMonitor()
        }
    ) {
        self.accountViewModel = accountViewModel
        self.supervisionRepository = supervisionRepository
        self.evidenceCaptureService = evidenceCaptureService
        self.seatMonitorFactory = seatMonitorFactory
        self.activityMonitorFactory = activityMonitorFactory
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
        let monitor = seatMonitorFactory()
        monitor.start()
        seatMonitor = monitor
        let activityMon = activityMonitorFactory()
        activityMon.start()
        activityMonitor = activityMon
    }

    func stopSupervision() {
        seatMonitor?.stop()
        seatMonitor = nil
        activityMonitor?.stop()
        activityMonitor = nil
        currentStateSnapshot = nil
    }

    func reportViolation(type: ViolationType) async {
        guard let snapshot = currentStateSnapshot else { return }
        let event = ViolationEventRecord(
            sessionID: snapshot.sessionID,
            roomID: snapshot.roomID,
            userID: snapshot.userID,
            violationType: type
        )
        try? await supervisionRepository.recordViolation(event)

        if let evidenceData = await evidenceCaptureService.captureEvidence(for: event.eventID) {
            let evidence = ViolationEvidenceRecord(
                eventID: event.eventID,
                sessionID: snapshot.sessionID,
                userID: snapshot.userID,
                imageDataBase64: evidenceData.base64EncodedString()
            )
            try? await supervisionRepository.uploadEvidence(evidence)
        }
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
    var activityMonitor: (any ActivityMonitorProtocol)? = nil
    var eligibility: SupervisionEligibility { permissionSnapshot.eligibility }

    func checkPermissions() async {}

    func startSupervision(sessionID: String, roomID: String, userID: String) {
        currentStateSnapshot = SupervisionStateSnapshot(sessionID: sessionID, roomID: roomID, userID: userID)
    }

    func stopSupervision() {
        currentStateSnapshot = nil
    }

    func reportViolation(type: ViolationType) async {}
}

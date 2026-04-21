import Foundation

@MainActor
protocol SeatMonitorProtocol: AnyObject {
    var seatState: SeatState { get }
    func start()
    func stop()
}

// Threshold: 3 consecutive missing frames before declaring away; 1 present frame to recover
@MainActor
final class SeatMonitor: SeatMonitorProtocol {
    private(set) var seatState: SeatState = .unknown
    
    private let pipeline: any SeatMonitorFramePipelineProtocol
    private let awayThreshold: Int
    private var consecutiveMissingFrames = 0
    
    init(
        pipeline: any SeatMonitorFramePipelineProtocol,
        awayThreshold: Int = 3
    ) {
        self.pipeline = pipeline
        self.awayThreshold = awayThreshold
    }
    
    func start() {
        seatState = .unknown
        consecutiveMissingFrames = 0
        pipeline.startCapturing { [weak self] presence in
            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self?.handlePresence(presence)
                }
            } else {
                Task { @MainActor [weak self] in
                    self?.handlePresence(presence)
                }
            }
        }
    }
    
    func stop() {
        pipeline.stopCapturing()
        seatState = .unknown
    }
    
    private func handlePresence(_ presence: PersonPresence) {
        switch presence {
        case .present:
            consecutiveMissingFrames = 0
            seatState = .present
        case .missing:
            consecutiveMissingFrames += 1
            if consecutiveMissingFrames >= awayThreshold {
                seatState = .away
            }
        }
    }
}

@MainActor
final class StubSeatMonitor: SeatMonitorProtocol {
    var seatState: SeatState = .unknown
    var didStart = false
    var didStop = false
    
    func start() { didStart = true }
    func stop() { didStop = true }
    
    func simulatePresence(_ state: SeatState) {
        seatState = state
    }
}

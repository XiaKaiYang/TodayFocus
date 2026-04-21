import Foundation

@MainActor
protocol ActivityMonitorProtocol: AnyObject {
    var activityState: ActivityState { get }
    func start()
    func stop()
    func recordUserInteraction()
}

/// Tracks whether the user is interacting with the machine.
/// Transitions to `inactive` after `inactivityThreshold` seconds without interaction.
@MainActor
final class ActivityMonitor: ActivityMonitorProtocol {
    private(set) var activityState: ActivityState = .unknown
    
    private let inactivityThreshold: TimeInterval
    private var lastInteractionDate: Date?
    private var checkTimer: Timer?
    
    init(inactivityThreshold: TimeInterval = 60) {
        self.inactivityThreshold = inactivityThreshold
    }
    
    func start() {
        activityState = .active
        lastInteractionDate = Date()
        scheduleTimer()
    }
    
    func stop() {
        checkTimer?.invalidate()
        checkTimer = nil
        activityState = .unknown
        lastInteractionDate = nil
    }
    
    func recordUserInteraction() {
        lastInteractionDate = Date()
        activityState = .active
    }
    
    private func scheduleTimer() {
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkActivity()
            }
        }
    }
    
    private func checkActivity() {
        guard let last = lastInteractionDate else { return }
        let elapsed = Date().timeIntervalSince(last)
        activityState = elapsed >= inactivityThreshold ? .inactive : .active
    }
}

@MainActor
final class StubActivityMonitor: ActivityMonitorProtocol {
    var activityState: ActivityState = .unknown
    var didStart = false
    var didStop = false
    var interactionCount = 0
    
    func start() { didStart = true; activityState = .active }
    func stop() { didStop = true; activityState = .unknown }
    func recordUserInteraction() { interactionCount += 1; activityState = .active }
    
    func simulateInactivity() { activityState = .inactive }
}

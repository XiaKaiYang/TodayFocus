import XCTest
import AppKit
import SwiftData
import FocusSessionCore
@testable import FocusSession

@MainActor
final class BlockerCoordinatorTests: XCTestCase {
    func testBlockedAppAttemptCreatesDistractionEvent() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let context = ModelContext(container)
        let rulesRepository = BlockingRuleRepository(modelContext: context)
        let eventRepository = DistractionEventRepository(modelContext: context)
        let intervention = TestBlockedAppIntervention()
        let coordinator = BlockerCoordinator(
            rulesRepository: rulesRepository,
            distractionEventRepository: eventRepository,
            intervention: intervention
        )

        try rulesRepository.save(
            BlockingRule(
                mode: .deny,
                target: .app(name: "Safari")
            )
        )

        coordinator.reloadRules()
        coordinator.isBlockingEnabled = true
        try coordinator.evaluateApp(named: "Safari")

        let events = try eventRepository.fetchAll()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].kind, .blockedApp(name: "Safari"))
        XCTAssertEqual(coordinator.lastBlockedAppName, "Safari")
        XCTAssertEqual(intervention.blockedAppNames, ["Safari"])
    }

    func testAllowedAppDoesNotTriggerIntervention() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let context = ModelContext(container)
        let rulesRepository = BlockingRuleRepository(modelContext: context)
        let eventRepository = DistractionEventRepository(modelContext: context)
        let intervention = TestBlockedAppIntervention()
        let coordinator = BlockerCoordinator(
            rulesRepository: rulesRepository,
            distractionEventRepository: eventRepository,
            intervention: intervention
        )

        try rulesRepository.save(
            BlockingRule(
                mode: .allow,
                target: .app(name: "Xcode")
            )
        )

        coordinator.reloadRules()
        coordinator.isBlockingEnabled = true
        try coordinator.evaluateApp(named: "Xcode")

        XCTAssertTrue(intervention.blockedAppNames.isEmpty)
    }
}

private final class TestBlockedAppIntervention: BlockedAppIntervening {
    private(set) var blockedAppNames: [String] = []

    func intervene(for appName: String, runningApplication: NSRunningApplication?) {
        blockedAppNames.append(appName)
    }
}

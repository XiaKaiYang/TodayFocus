import Foundation
import SwiftData
import FocusSessionCore

@Model
final class StoredDistractionEvent {
    @Attribute(.unique) var id: UUID
    var kindType: String
    var payload: String
    var occurredAt: Date

    init(event: DistractionEvent) {
        self.id = event.id
        self.occurredAt = event.occurredAt

        switch event.kind {
        case let .blockedApp(name):
            self.kindType = "app"
            self.payload = name
        case let .blockedWebsite(host):
            self.kindType = "website"
            self.payload = host
        }
    }

    var domainModel: DistractionEvent {
        DistractionEvent(
            id: id,
            kind: kind,
            occurredAt: occurredAt
        )
    }

    private var kind: DistractionEventKind {
        switch kindType {
        case "website":
            .blockedWebsite(host: payload)
        default:
            .blockedApp(name: payload)
        }
    }
}

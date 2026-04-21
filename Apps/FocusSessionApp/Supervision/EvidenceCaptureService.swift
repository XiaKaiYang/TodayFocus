import Foundation

protocol EvidenceCaptureServiceProtocol: Sendable {
    func captureEvidence(for eventID: String) async -> Data?
}

struct EvidenceCaptureService: EvidenceCaptureServiceProtocol, Sendable {
    func captureEvidence(for eventID: String) async -> Data? {
        // Production: capture camera frame or screen snapshot here
        return nil
    }
}

struct StubEvidenceCaptureService: EvidenceCaptureServiceProtocol, Sendable {
    var stubbedData: Data?
    init(stubbedData: Data? = nil) { self.stubbedData = stubbedData }
    func captureEvidence(for eventID: String) async -> Data? { stubbedData }
}

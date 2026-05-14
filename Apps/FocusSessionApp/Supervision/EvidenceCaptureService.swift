import Foundation
#if os(macOS)
import AppKit
import ScreenCaptureKit
#endif

protocol EvidenceCaptureServiceProtocol: Sendable {
    func captureEvidence(for eventID: String) async -> Data?
}

struct EvidenceCaptureService: EvidenceCaptureServiceProtocol, Sendable {
    func captureEvidence(for eventID: String) async -> Data? {
        #if os(macOS)
        return await captureScreenEvidence()
        #else
        return nil
        #endif
    }

    #if os(macOS)
    private func captureScreenEvidence() async -> Data? {
        guard
            let shareableContent = try? await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true),
            let display = shareableContent.displays.first
        else {
            return nil
        }

        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.width = Int(display.width)
        configuration.height = Int(display.height)

        guard let image = try? await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        ) else {
            return nil
        }

        let bitmap = NSBitmapImageRep(cgImage: image)
        return bitmap.representation(using: .png, properties: [:])
    }
    #endif
}

struct StubEvidenceCaptureService: EvidenceCaptureServiceProtocol, Sendable {
    var stubbedData: Data?
    init(stubbedData: Data? = nil) { self.stubbedData = stubbedData }
    func captureEvidence(for eventID: String) async -> Data? { stubbedData }
}

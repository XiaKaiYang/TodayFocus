import Foundation

enum PersonPresence: Equatable {
    case present
    case missing
}

protocol SeatMonitorFramePipelineProtocol: AnyObject, Sendable {
    /// Called on an arbitrary background thread. Deliver presence updates via callback.
    func startCapturing(onPresence: @escaping @Sendable (PersonPresence) -> Void)
    func stopCapturing()
}

// Stub for testing — emits frames programmatically
final class StubSeatMonitorFramePipeline: SeatMonitorFramePipelineProtocol, @unchecked Sendable {
    var onPresence: (@Sendable (PersonPresence) -> Void)?

    func startCapturing(onPresence: @escaping @Sendable (PersonPresence) -> Void) {
        self.onPresence = onPresence
    }

    func stopCapturing() {
        onPresence = nil
    }

    func emit(_ presence: PersonPresence) {
        onPresence?(presence)
    }
}

#if os(macOS)
import AVFoundation
import Vision

final class SeatMonitorFramePipeline: NSObject, SeatMonitorFramePipelineProtocol, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    private var captureSession: AVCaptureSession?
    private var onPresence: (@Sendable (PersonPresence) -> Void)?
    private let processingQueue = DispatchQueue(label: "SeatMonitorFramePipeline", qos: .userInitiated)

    func startCapturing(onPresence: @escaping @Sendable (PersonPresence) -> Void) {
        self.onPresence = onPresence
        setupCaptureSession()
    }

    func stopCapturing() {
        onPresence = nil
        captureSession?.stopRunning()
        captureSession = nil
    }

    private func setupCaptureSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .low

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                ?? AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device)
        else { return }

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: processingQueue)
        output.alwaysDiscardsLateVideoFrames = true

        guard session.canAddInput(input), session.canAddOutput(output) else { return }
        session.addInput(input)
        session.addOutput(output)

        captureSession = session
        session.startRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let request = VNDetectFaceRectanglesRequest { [weak self] request, _ in
            let hasFace = !(request.results?.isEmpty ?? true)
            self?.onPresence?(hasFace ? .present : .missing)
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}
#endif

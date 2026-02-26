import AVFoundation
import Combine

class QrCameraManagerNew: NSObject {
    private let captureSession = AVCaptureSession()
    private let scanQueue = DispatchQueue(label: "io.horizontalsystems.unstoppable.qr_camera_new", qos: .default)
    private let scannedSubject = PassthroughSubject<String, Never>()
    private let errorSubject = PassthroughSubject<Error, Never>()
    private var isConfigured = false

    var scannedPublisher: AnyPublisher<String, Never> {
        scannedSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    var session: AVCaptureSession {
        captureSession
    }

    func configure() {
        scanQueue.async { [weak self] in
            guard let self, !isConfigured else { return }

            do {
                let device = try Self.backCamera()
                let input = try AVCaptureDeviceInput(device: device)

                guard captureSession.canAddInput(input) else { return }
                captureSession.addInput(input)

                let metadataOutput = AVCaptureMetadataOutput()
                guard captureSession.canAddOutput(metadataOutput) else { return }
                captureSession.addOutput(metadataOutput)

                metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
                metadataOutput.metadataObjectTypes = [.qr]

                isConfigured = true
            } catch {
                errorSubject.send(error)
            }
        }
    }

    func start() {
        scanQueue.async { [weak self] in
            guard let self, !captureSession.isRunning else { return }
            captureSession.startRunning()
        }
    }

    func stop() {
        scanQueue.async { [weak self] in
            guard let self, captureSession.isRunning else { return }
            captureSession.stopRunning()
        }
    }

    private static func backCamera() throws -> AVCaptureDevice {
        if let device = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
            return device
        }
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            return device
        }
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return device
        }
        throw CameraError.noBackCamera
    }

    enum CameraError: Error {
        case noBackCamera
    }
}

extension QrCameraManagerNew: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from _: AVCaptureConnection) {
        if let readable = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let value = readable.stringValue
        {
            scannedSubject.send(value)
        }
    }
}

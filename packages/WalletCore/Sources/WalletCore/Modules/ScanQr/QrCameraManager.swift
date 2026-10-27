import AVFoundation
import Combine

final class QrCameraManager: NSObject {
    private let captureSession = AVCaptureSession()
    private let scanQueue = DispatchQueue(label: "io.horizontalsystems.unstoppable.qr_camera", qos: .default)
    private let scannedSubject = PassthroughSubject<String, Never>()
    private let errorSubject = PassthroughSubject<Error, Never>()
    private let configuredSubject = PassthroughSubject<Void, Never>()
    private var isConfigured = false

    var scannedPublisher: AnyPublisher<String, Never> {
        scannedSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    var configuredPublisher: AnyPublisher<Void, Never> {
        configuredSubject.eraseToAnyPublisher()
    }

    var session: AVCaptureSession {
        captureSession
    }

    func configure() {
        scanQueue.async { [weak self] in
            guard let self, !isConfigured else { return }

            var addedInput: AVCaptureInput?
            var addedOutput: AVCaptureOutput?

            captureSession.beginConfiguration()

            do {
                let device = try Self.backCamera()
                let input = try AVCaptureDeviceInput(device: device)

                guard captureSession.canAddInput(input) else { throw CameraError.cannotAddInput }
                captureSession.addInput(input)
                addedInput = input

                let metadataOutput = AVCaptureMetadataOutput()
                guard captureSession.canAddOutput(metadataOutput) else { throw CameraError.cannotAddOutput }
                captureSession.addOutput(metadataOutput)
                addedOutput = metadataOutput

                metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
                metadataOutput.metadataObjectTypes = [.qr]

                captureSession.commitConfiguration()
                isConfigured = true
                configuredSubject.send()
            } catch {
                if let addedOutput {
                    captureSession.removeOutput(addedOutput)
                }
                if let addedInput {
                    captureSession.removeInput(addedInput)
                }
                captureSession.commitConfiguration()
                errorSubject.send(error)
            }
        }
    }

    func start() {
        scanQueue.async { [weak self] in
            guard let self, isConfigured, !captureSession.isRunning else { return }
            captureSession.startRunning()
        }
    }

    func stop() {
        scanQueue.async {
            guard self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
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
        case cannotAddInput
        case cannotAddOutput
    }
}

extension QrCameraManager: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from _: AVCaptureConnection) {
        if let readable = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let value = readable.stringValue
        {
            scannedSubject.send(value)
        }
    }
}

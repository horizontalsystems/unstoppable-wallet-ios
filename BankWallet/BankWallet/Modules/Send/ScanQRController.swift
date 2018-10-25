import UIKit
import AVFoundation
import SnapKit

class ScanQRController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!

    var onCodeParse: ((String) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()

        PermissionsHelper.shared.performWithCameraPermission(fromController: self) { [weak self] in
            self?.initialSetup()
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession);
        previewLayer.frame = view.layer.bounds;
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill;
        view.layer.addSublayer(previewLayer);

        captureSession.startRunning();

        let closeButton = UIButton()
        closeButton.setTitle("alert.cancel".localized, for: .normal)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        let safeButt = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0

        let container = UIView()
        view.addSubview(container)
        container.backgroundColor = .black
        container.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(safeButt + 44)
        }
        container.addSubview(closeButton)
        closeButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.height.equalTo(44)
            maker.trailing.equalToSuperview().offset(-16)
        }
    }

    func initialSetup() {
        do {
            let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video)
            let videoInput: AVCaptureDeviceInput

            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice!)
            if (captureSession.canAddInput(videoInput)) {
                captureSession.addInput(videoInput)
            } else {
                failed();
            }

            let metadataOutput = AVCaptureMetadataOutput()
            if (captureSession.canAddOutput(metadataOutput)) {
                captureSession.addOutput(metadataOutput)

                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.ean8, AVMetadataObject.ObjectType.ean13, AVMetadataObject.ObjectType.pdf417, AVMetadataObject.ObjectType.qr]
            } else {
                failed()
            }
        } catch {
        }
    }

    @objc func close() {
        dismiss(animated: true)
    }

    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (captureSession?.isRunning == false) {
            captureSession.startRunning();
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (captureSession?.isRunning == true) {
            captureSession.stopRunning();
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            let readableObject = metadataObject as! AVMetadataMachineReadableCodeObject;

            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: readableObject.stringValue!);
        }

        dismiss(animated: true)
    }

    func found(code: String) {
        onCodeParse?(code)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

}

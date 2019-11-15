import UIKit
import AVFoundation
import SnapKit

class ScanQRController: UIViewController {
    weak var delegate: IScanQrCodeDelegate?

    private var captureSession: AVCaptureSession!
    private var initiallySetUp = false

    private var willAppear = false

    init(delegate: IScanQrCodeDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black

        captureSession = AVCaptureSession()

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.layer.addSublayer(previewLayer)

        let closeButton = UIButton()
        closeButton.setTitle("button.cancel".localized, for: .normal)
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let captureSession = captureSession, !captureSession.isRunning {
            captureSession.startRunning()
        }

        willAppear = true
        UIView.animate(withDuration: 0.5) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !initiallySetUp {
            initiallySetUp = true

            PermissionsHelper.shared.performWithCameraPermission(fromController: self) { [weak self] in
                self?.initialSetup()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let captureSession = captureSession, captureSession.isRunning {
            captureSession.stopRunning()
        }

        willAppear = false
        UIView.animate(withDuration: 0.5) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var prefersStatusBarHidden: Bool {
        willAppear
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    @objc func close() {
        dismiss(animated: true)
    }

    private func initialSetup() {
        do {
            let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video)
            let videoInput: AVCaptureDeviceInput

            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice!)
            if (captureSession.canAddInput(videoInput)) {
                captureSession.addInput(videoInput)
            } else {
                failed()
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

    private func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    private func found(code: String) {
        delegate?.didScan(string: code)
    }

}

extension ScanQRController: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first,
            let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
            let stringValue = readableObject.stringValue {

            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }

        dismiss(animated: true)
    }

}

protocol IScanQrCodeDelegate: AnyObject {
    func didScan(string: String)
}

import UIKit
import SnapKit
import ThemeKit
import ScanQrKit
import ComponentKit

protocol IScanQrViewControllerDelegate: AnyObject {
    func didScan(viewController: UIViewController, string: String)
}

class ScanQrViewController: ThemeViewController, IDismissDelegate {
    weak var delegate: IScanQrViewControllerDelegate?

    private let scanView = ScanQrView()
    private let cancelButton = PrimaryButton()

    var onUserDismissed: (() -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(scanView)
        scanView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        scanView.delegate = self

        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(CGFloat.margin24)
        }

        cancelButton.set(style: .gray)
        cancelButton.setTitle("button.cancel".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(onCancel), for: .touchUpInside)

        scanView.start()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        scanView.startCaptureSession()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        scanView.stop()
    }

    @objc func onCancel() {
        onUserDismissed?()
        dismiss(animated: true)
    }

    func startCaptureSession() {
        scanView.startCaptureSession()
    }

    func onScan(string: String) {
        delegate?.didScan(viewController: self, string: string)
        onUserDismissed?()
        dismiss(animated: true)
    }

}

extension ScanQrViewController: IScanQrCodeDelegate {

    func didScan(string: String) {
        scanView.stop()
        onScan(string: string)
    }

}

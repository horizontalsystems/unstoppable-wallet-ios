import ComponentKit
import ScanQrKit
import SnapKit
import ThemeKit
import UIKit

class ScanQrViewController: ThemeViewController {
    private let scanView: ScanQrView

    private let reportAfterDismiss: Bool
    private let pasteEnabled: Bool

    var didFetch: ((String) -> Void)?

    init(reportAfterDismiss: Bool = false, pasteEnabled: Bool = false) {
        self.reportAfterDismiss = reportAfterDismiss
        self.pasteEnabled = pasteEnabled

        let bottomInset: CGFloat = .margin24 + PrimaryButton.height + (pasteEnabled ? .margin16 + PrimaryButton.height : 0)
        scanView = ScanQrView(bottomInset: bottomInset)

        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(scanView)
        scanView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        scanView.delegate = self

        let cancelButton = PrimaryButton()

        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(CGFloat.margin24)
        }

        cancelButton.set(style: .gray)
        cancelButton.setTitle("button.cancel".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(onCancel), for: .touchUpInside)

        if pasteEnabled {
            let pasteButton = PrimaryButton()

            view.addSubview(pasteButton)
            pasteButton.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
                maker.bottom.equalTo(cancelButton.snp.top).offset(-CGFloat.margin16)
            }

            pasteButton.set(style: .yellow)
            pasteButton.setTitle("button.paste".localized, for: .normal)
            pasteButton.addTarget(self, action: #selector(onPaste), for: .touchUpInside)
        }

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

    @objc private func onCancel() {
        dismiss(animated: true)
    }

    @objc private func onPaste() {
        onFetch(string: UIPasteboard.general.string ?? "")
    }

    private func onFetch(string: String) {
        if reportAfterDismiss {
            dismiss(animated: true) { [weak self] in
                self?.didFetch?(string)
            }
        } else {
            didFetch?(string)
            dismiss(animated: true)
        }
    }
}

extension ScanQrViewController: IScanQrCodeDelegate {
    func didScan(string: String) {
        scanView.stop()
        onFetch(string: string)
    }
}

import UIKit
import SnapKit
import ThemeKit
import ScanQrKit

class ScanQrViewController: ThemeViewController {
    private let delegate: IScanQrViewDelegate

    private let errorLabel = UILabel()
    private let cancelButton = ThemeButton()

    private let scanView = ScanQrView()

    init(delegate: IScanQrViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(scanView)
        scanView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        scanView.delegate = self

        view.addSubview(errorLabel)
        errorLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.centerY.equalToSuperview().dividedBy(3)
        }

        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.textColor = .themeLucian
        errorLabel.font = .subhead2

        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        cancelButton.apply(style: .primaryGray)
        cancelButton.setTitle("button.cancel".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(onCancel), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        scanView.start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        scanView.stop()
    }

    @objc private func onCancel() {
        delegate.onCancel()
    }

}

extension ScanQrViewController: IScanQrView {

    func start() {
        scanView.start()
    }

    func stop() {
        scanView.stop()
    }

    func set(error: Error) {
        errorLabel.text = error.smartDescription
    }

}

extension ScanQrViewController: IScanQrCodeDelegate {

    func didScan(string: String) {
        delegate.didScan(string: string)
    }

}

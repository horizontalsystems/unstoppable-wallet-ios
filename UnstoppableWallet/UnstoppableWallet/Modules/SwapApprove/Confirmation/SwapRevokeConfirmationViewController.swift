import UIKit
import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import ComponentKit

class SwapRevokeConfirmationViewController: SendEvmTransactionViewController {
    private let approveButton = PrimaryButton()
    private let cancelButton = PrimaryButton()
    private weak var delegate: ISwapApproveDelegate?

    init(transactionViewModel: SendEvmTransactionViewModel, settingsViewModel: EvmSendSettingsViewModel, delegate: ISwapApproveDelegate?) {
        self.delegate = delegate

        super.init(transactionViewModel: transactionViewModel, settingsViewModel: settingsViewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "confirm".localized

        bottomWrapper.addSubview(approveButton)

        approveButton.set(style: .yellow)
        approveButton.setTitle("button.revoke".localized, for: .normal)
        approveButton.addTarget(self, action: #selector(onTapApprove), for: .touchUpInside)

        bottomWrapper.addSubview(cancelButton)

        cancelButton.set(style: .gray)
        cancelButton.setTitle("button.cancel".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(onTapCancel), for: .touchUpInside)

        subscribe(disposeBag, transactionViewModel.sendEnabledDriver) { [weak self] in self?.approveButton.isEnabled = $0 }
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    @objc private func onTapApprove() {
        transactionViewModel.send()
    }

    override func handleSending() {
        HudHelper.instance.show(banner: .revoking)
    }

    override func handleSendSuccess(transactionHash: Data) {
        delegate?.didApprove()
        HudHelper.instance.show(banner: .revoked)

        super.handleSendSuccess(transactionHash: transactionHash)
    }

}

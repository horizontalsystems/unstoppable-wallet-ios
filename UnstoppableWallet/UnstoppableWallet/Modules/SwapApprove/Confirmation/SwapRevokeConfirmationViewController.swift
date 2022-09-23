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

    init(transactionViewModel: SendEvmTransactionViewModel, feeViewModel: EvmFeeViewModel, delegate: ISwapApproveDelegate?) {
        self.delegate = delegate

        super.init(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "confirm".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .done, target: self, action: #selector(onTapCancel))

        bottomWrapper.addSubview(approveButton)
        approveButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin32)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
        }

        approveButton.set(style: .yellow)
        approveButton.setTitle("button.revoke".localized, for: .normal)
        approveButton.addTarget(self, action: #selector(onTapApprove), for: .touchUpInside)

        bottomWrapper.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { maker in
            maker.top.equalTo(approveButton.snp.bottom).offset(CGFloat.margin16)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
        }

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

import UIKit
import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import ComponentKit

class SwapApproveConfirmationViewController: SendEvmTransactionViewController {
    private let approveButton = PrimaryButton()
    private weak var delegate: ISwapApproveDelegate?

    init(transactionViewModel: SendEvmTransactionViewModel, settingsService: EvmSendSettingsService, feeViewModel: EvmFeeViewModel, delegate: ISwapApproveDelegate?) {
        self.delegate = delegate

        super.init(transactionViewModel: transactionViewModel, settingsService: settingsService, feeViewModel: feeViewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "confirm".localized

        bottomWrapper.addSubview(approveButton)
        approveButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin32)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
        }

        approveButton.set(style: .yellow)
        approveButton.setTitle("button.approve".localized, for: .normal)
        approveButton.addTarget(self, action: #selector(onTapApprove), for: .touchUpInside)

        subscribe(disposeBag, transactionViewModel.sendEnabledDriver) { [weak self] in self?.approveButton.isEnabled = $0 }
    }

    @objc private func onTapApprove() {
        transactionViewModel.send()
    }

    override func handleSending() {
        HudHelper.instance.show(banner: .approving)
    }

    override func handleSendSuccess(transactionHash: Data) {
        delegate?.didApprove()
        HudHelper.instance.show(banner: .approved)

        super.handleSendSuccess(transactionHash: transactionHash)
    }

}

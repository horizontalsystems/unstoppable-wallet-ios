import UIKit
import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import ComponentKit

class SendEvmConfirmationViewController: SendEvmTransactionViewController {
    private let sendButton = PrimaryButton()

    var confirmationTitle = "confirm".localized
    var confirmationButtonTitle = "send.confirmation.send_button".localized

    override func viewDidLoad() {
        super.viewDidLoad()

        title = confirmationTitle

        bottomWrapper.addSubview(sendButton)

        sendButton.set(style: .yellow)
        sendButton.setTitle(confirmationButtonTitle, for: .normal)
        sendButton.addTarget(self, action: #selector(onTapSend), for: .touchUpInside)

        subscribe(disposeBag, transactionViewModel.sendEnabledDriver) { [weak self] in self?.sendButton.isEnabled = $0 }
    }

    @objc private func onTapSend() {
        transactionViewModel.send()
    }

    override func handleSending() {
        HudHelper.instance.show(banner: .sending)
    }

    override func handleSendSuccess(transactionHash: Data) {
        HudHelper.instance.show(banner: .sent)

        super.handleSendSuccess(transactionHash: transactionHash)
    }

}

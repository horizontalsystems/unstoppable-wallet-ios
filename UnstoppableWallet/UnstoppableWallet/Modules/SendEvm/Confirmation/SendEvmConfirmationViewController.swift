import UIKit
import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import ComponentKit

class SendEvmConfirmationViewController: SendEvmTransactionViewController {
    private let sendButton = ThemeButton()

    var confirmationTitle = "confirm"
    var confirmationButtonTitle = "send.confirmation.send_button"

    override func viewDidLoad() {
        super.viewDidLoad()

        title = confirmationTitle.localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))

        bottomWrapper.addSubview(sendButton)
        sendButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin32)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        sendButton.apply(style: .primaryYellow)
        sendButton.setTitle(confirmationButtonTitle.localized, for: .normal)
        sendButton.addTarget(self, action: #selector(onTapSend), for: .touchUpInside)

        subscribe(disposeBag, transactionViewModel.sendEnabledDriver) { [weak self] in self?.sendButton.isEnabled = $0 }
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    @objc private func onTapSend() {
        transactionViewModel.send()
    }

}

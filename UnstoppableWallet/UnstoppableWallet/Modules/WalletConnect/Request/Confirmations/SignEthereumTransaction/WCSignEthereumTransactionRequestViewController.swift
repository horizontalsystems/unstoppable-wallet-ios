import ComponentKit
import Foundation
import RxSwift
import ThemeKit
import UIKit

class WCSignEthereumTransactionRequestViewController: SendEvmTransactionViewController {
    private let viewModel: WCSignEthereumTransactionRequestViewModel

    private let signButton = PrimaryButton()
    private let rejectButton = PrimaryButton()

    init(viewModel: WCSignEthereumTransactionRequestViewModel, transactionViewModel: SendEvmTransactionViewModel, settingsViewModel: EvmSendSettingsViewModel) {
        self.viewModel = viewModel

        super.init(transactionViewModel: transactionViewModel, settingsViewModel: settingsViewModel)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "wallet_connect.sign.request_title".localized
        isModalInPresentation = true

        bottomWrapper.addSubview(signButton)

        signButton.set(style: .yellow)
        signButton.setTitle("button.sign".localized, for: .normal)
        signButton.addTarget(self, action: #selector(onTapSign), for: .touchUpInside)

        bottomWrapper.addSubview(rejectButton)

        rejectButton.set(style: .gray)
        rejectButton.setTitle("button.reject".localized, for: .normal)
        rejectButton.addTarget(self, action: #selector(onTapReject), for: .touchUpInside)

        subscribe(disposeBag, viewModel.errorSignal) { [weak self] in self?.show(error: $0) }
        subscribe(disposeBag, viewModel.dismissSignal) { [weak self] in self?.dismiss() }
    }

    @objc private func onTapSign() {
        viewModel.sign()
    }

    @objc private func onTapReject() {
        viewModel.reject()
        dismiss(animated: true)
    }

    private func show(error: Error) {
        HudHelper.instance.show(banner: .error(string: error.localizedDescription))
    }

    private func dismiss() {
        dismiss(animated: true)
    }
}

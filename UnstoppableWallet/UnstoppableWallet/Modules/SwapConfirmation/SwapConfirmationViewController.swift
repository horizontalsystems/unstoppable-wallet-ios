import UIKit
import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import ComponentKit

class SwapConfirmationViewController: SendEvmTransactionViewController {
    private let swapButton = PrimaryButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "confirm".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .done, target: self, action: #selector(onTapCancel))

        bottomWrapper.addSubview(swapButton)
        swapButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin32)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
        }

        swapButton.set(style: .yellow)
        swapButton.setTitle("swap.confirmation.swap_button".localized, for: .normal)
        swapButton.addTarget(self, action: #selector(onTapSwap), for: .touchUpInside)

        subscribe(disposeBag, transactionViewModel.sendEnabledDriver) { [weak self] in self?.swapButton.isEnabled = $0 }
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    @objc private func onTapSwap() {
        transactionViewModel.send()
    }

    override func handleSending() {
        HudHelper.instance.show(banner: .swapping)
    }

    override func handleSendSuccess(transactionHash: Data) {
        HudHelper.instance.show(banner: .swapped)

        super.handleSendSuccess(transactionHash: transactionHash)
    }


}

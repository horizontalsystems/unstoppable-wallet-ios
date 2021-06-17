import UIKit
import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import ComponentKit

class SwapConfirmationViewController: SendEvmTransactionViewController {
    private let swapButton = ThemeButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "confirm".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .done, target: self, action: #selector(onTapCancel))

        bottomWrapper.addSubview(swapButton)
        swapButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin32)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        swapButton.apply(style: .primaryYellow)
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

}

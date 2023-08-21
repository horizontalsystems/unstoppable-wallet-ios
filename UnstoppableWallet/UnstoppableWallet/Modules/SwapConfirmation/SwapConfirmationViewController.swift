import UIKit
import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import ComponentKit

class SwapConfirmationViewController: SendEvmTransactionViewController {
    private let swapButton = SliderButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "confirm".localized

        bottomWrapper.addSubview(swapButton)

        swapButton.title = "swap.confirmation.slide_to_swap".localized
        swapButton.finalTitle = "swap.confirmation.swapping".localized
        swapButton.slideImage = UIImage(named: "arrow_medium_2_right_24")
        swapButton.finalImage = UIImage(named: "check_2_24")
        swapButton.onTap = { [weak self] in
            self?.transactionViewModel.send()
        }

        subscribe(disposeBag, transactionViewModel.sendEnabledDriver) { [weak self] in self?.swapButton.isEnabled = $0 }
    }

    override func handleSending() {
        HudHelper.instance.show(banner: .swapping)
    }

    override func handleSendSuccess(transactionHash: Data) {
        HudHelper.instance.show(banner: .swapped)

        super.handleSendSuccess(transactionHash: transactionHash)
    }

    override func handleSendFailed(error: String) {
        super.handleSendFailed(error: error)

        swapButton.reset()
    }

}

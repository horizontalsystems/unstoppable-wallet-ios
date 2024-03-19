import ComponentKit
import MarketKit
import RxCocoa
import RxSwift
import SnapKit
import SwiftUI
import ThemeKit
import UIKit

class SwapApproveConfirmationViewController: SendEvmTransactionViewController {
    private let approveButton = PrimaryButton()
    private weak var delegate: ISwapApproveDelegate?

    init(transactionViewModel: SendEvmTransactionViewModel, settingsViewModel: EvmSendSettingsViewModel, delegate: ISwapApproveDelegate?) {
        self.delegate = delegate

        super.init(transactionViewModel: transactionViewModel, settingsViewModel: settingsViewModel)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "confirm".localized

        bottomWrapper.addSubview(approveButton)

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

struct SwapApproveConfirmationView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let sendData: SendEvmData
    let blockchainType: BlockchainType
    weak var delegate: ISwapApproveDelegate?

    init(sendData: SendEvmData, blockchainType: BlockchainType, delegate: ISwapApproveDelegate?) {
        self.sendData = sendData
        self.blockchainType = blockchainType
        self.delegate = delegate
    }

    func makeUIViewController(context _: Context) -> UIViewController {
        do {
            let viewController = try SwapApproveConfirmationModule.viewController(
                sendData: sendData,
                blockchainType: blockchainType,
                delegate: delegate
            )
            return ThemeNavigationController(rootViewController: viewController)
        } catch {
            return ThemeNavigationController(rootViewController: ErrorViewController(text: error.localizedDescription))
        }
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}

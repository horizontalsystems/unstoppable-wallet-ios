import UIKit

struct WalletConnectSendEthereumTransactionRequestModule {

    static func viewController(transaction: WalletConnectTransaction, onApprove: @escaping (Data) -> (), onReject: @escaping () -> ()) -> UIViewController? {
        guard let ethereumKit = App.shared.ethereumKitManager.ethereumKit else {
            return nil
        }

        let service = WalletConnectSendEthereumTransactionRequestService(
                ethereumKit: ethereumKit,
                appConfigProvider: App.shared.appConfigProvider,
                currencyKit: App.shared.currencyKit,
                rateManager: App.shared.rateManager
        )

        let viewModel = WalletConnectSendEthereumTransactionRequestViewModel(service: service, transaction: transaction)

        return WalletConnectRequestViewController(viewModel: viewModel, onApprove: onApprove, onReject: onReject)
    }

}

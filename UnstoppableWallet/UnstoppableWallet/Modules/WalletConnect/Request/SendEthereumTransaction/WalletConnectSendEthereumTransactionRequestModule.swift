import UIKit

struct WalletConnectSendEthereumTransactionRequestModule {

    static func viewController(baseViewModel: WalletConnectViewModel, request: WalletConnectSendEthereumTransactionRequest) -> UIViewController? {
        guard let ethereumKit = App.shared.ethereumKitManager.ethereumKit else {
            return nil
        }

        let service = WalletConnectSendEthereumTransactionRequestService(
                ethereumKit: ethereumKit,
                appConfigProvider: App.shared.appConfigProvider,
                currencyKit: App.shared.currencyKit,
                rateManager: App.shared.rateManager
        )

        let viewModel = WalletConnectSendEthereumTransactionRequestViewModel(service: service, request: request)

        return WalletConnectRequestViewController(baseViewModel: baseViewModel, viewModel: viewModel)
    }

}

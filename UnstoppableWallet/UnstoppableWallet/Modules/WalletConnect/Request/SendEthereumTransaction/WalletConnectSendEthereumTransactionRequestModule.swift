import UIKit

struct WalletConnectSendEthereumTransactionRequestModule {

    static func viewController(transaction: WalletConnectTransaction, onApprove: @escaping (Data) -> (), onReject: @escaping () -> ()) -> UIViewController? {
        guard let ethereumKit = App.shared.ethereumKitManager.ethereumKit else {
            return nil
        }

        let coinService = CoinService(
                coin: App.shared.appConfigProvider.ethereumCoin,
                currencyKit: App.shared.currencyKit,
                rateManager: App.shared.rateManager
        )

        let transactionService = EthereumTransactionService(
                ethereumKit: ethereumKit,
                feeRateProvider: App.shared.feeRateProviderFactory.provider(coinType: .ethereum) as! EthereumFeeRateProvider,
                gasLimitSurchargePercent: 10
        )

        let service = WalletConnectSendEthereumTransactionRequestService(
                transaction: transaction,
                transactionService: transactionService,
                ethereumKit: ethereumKit
        )

        let viewModel = WalletConnectSendEthereumTransactionRequestViewModel(service: service, coinService: coinService)
        let feeViewModel = EthereumFeeViewModel(service: transactionService, coinService: coinService)

        return WalletConnectRequestViewController(viewModel: viewModel, feeViewModel: feeViewModel, onApprove: onApprove, onReject: onReject)
    }

}

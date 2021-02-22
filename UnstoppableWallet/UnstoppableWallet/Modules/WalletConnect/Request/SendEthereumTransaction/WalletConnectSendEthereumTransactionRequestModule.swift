import UIKit
import EthereumKit

struct WalletConnectSendEthereumTransactionRequestModule {

    static func viewController(baseService: WalletConnectService, requestId: Int) -> UIViewController? {
        guard let request = baseService.pendingRequest(requestId: requestId) as? WalletConnectSendEthereumTransactionRequest, let evmKit = baseService.evmKit else {
            return nil
        }

        let coin: Coin

        switch evmKit.networkType {
        case .ethMainNet, .kovan, .ropsten: coin = App.shared.appConfigProvider.ethereumCoin
        case .bscMainNet: coin = App.shared.appConfigProvider.binanceSmartChainCoin
        }

        guard let feeRateProvider = App.shared.feeRateProviderFactory.provider(coinType: coin.type) else {
            return nil
        }

        let coinService = CoinService(
                coin: coin,
                currencyKit: App.shared.currencyKit,
                rateManager: App.shared.rateManager
        )

        let transactionService = EvmTransactionService(
                evmKit: evmKit,
                feeRateProvider: feeRateProvider,
                gasLimitSurchargePercent: 10
        )

        let service = WalletConnectSendEthereumTransactionRequestService(
                request: request,
                baseService: baseService,
                transactionService: transactionService,
                evmKit: evmKit
        )

        let viewModel = WalletConnectSendEthereumTransactionRequestViewModel(service: service, coinService: coinService)
        let feeViewModel = EthereumFeeViewModel(service: transactionService, coinService: coinService)

        return WalletConnectRequestViewController(viewModel: viewModel, feeViewModel: feeViewModel)
    }

}

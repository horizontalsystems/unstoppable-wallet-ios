import UIKit
import EthereumKit
import CoinKit

struct WalletConnectSendEthereumTransactionRequestModule {

    static func viewController(baseService: WalletConnectService, requestId: Int) -> UIViewController? {
        guard let request = baseService.pendingRequest(requestId: requestId) as? WalletConnectSendEthereumTransactionRequest, let evmKit = baseService.evmKit else {
            return nil
        }

        let feeCoin: Coin?

        switch evmKit.networkType {
        case .ethMainNet, .kovan, .ropsten: feeCoin = App.shared.coinKit.coin(type: .ethereum)
        case .bscMainNet: feeCoin = App.shared.coinKit.coin(type: .binanceSmartChain)
        }

        guard let coin = feeCoin, let feeRateProvider = App.shared.feeRateProviderFactory.provider(coinType: coin.type) else {
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

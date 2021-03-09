import UIKit
import ThemeKit
import EthereumKit
import CoinKit

struct SendEvmConfirmationModule {

    static func viewController(evmKit: EthereumKit.Kit, transactionData: TransactionData) -> UIViewController? {
        let feeCoin: Coin?

        switch evmKit.networkType {
        case .ethMainNet, .kovan, .ropsten: feeCoin = App.shared.coinKit.coin(type: .ethereum)
        case .bscMainNet: feeCoin = App.shared.coinKit.coin(type: .binanceSmartChain)
        }

        guard let coin = feeCoin, let feeRateProvider = App.shared.feeRateProviderFactory.provider(coinType: coin.type) else {
            return nil
        }

        let coinServiceFactory = EvmCoinServiceFactory(baseCoin: coin, coinKit: App.shared.coinKit, currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManager)
        let transactionService = EvmTransactionService(evmKit: evmKit, feeRateProvider: feeRateProvider)
        let service = SendEvmTransactionService(transactionData: transactionData, evmKit: evmKit, transactionService: transactionService)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory)
        let feeViewModel = EthereumFeeViewModel(service: transactionService, coinService: coinServiceFactory.baseCoinService)

        return SendEvmConfirmationViewController(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel)
    }

}

import UIKit
import ThemeKit
import EthereumKit
import CoinKit

struct SendEvmData {
    let transactionData: TransactionData
    let additionalItems: [AdditionalItem]

    enum AdditionalItem {
        case domain(value: String)
    }

}

struct SendEvmConfirmationModule {

    static func viewController(evmKit: EthereumKit.Kit, sendData: SendEvmData) -> UIViewController? {
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
        let service = SendEvmTransactionService(sendData: sendData, evmKit: evmKit, transactionService: transactionService)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory)
        let feeViewModel = EthereumFeeViewModel(service: transactionService, coinService: coinServiceFactory.baseCoinService)

        return SendEvmConfirmationViewController(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel)
    }

}

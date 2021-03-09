import UIKit
import ThemeKit
import EthereumKit

struct SwapApproveConfirmationModule {

    static func viewController(transactionData: TransactionData, dex: SwapModule.Dex, delegate: ISwapApproveDelegate?) -> UIViewController? {
        guard let coin = dex.coin, let evmKit = dex.evmKit, let feeRateProvider = App.shared.feeRateProviderFactory.provider(coinType: coin.type) else {
            return nil
        }

        let coinServiceFactory = EvmCoinServiceFactory(baseCoin: coin, coinKit: App.shared.coinKit, currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManager)
        let transactionService = EvmTransactionService(evmKit: evmKit, feeRateProvider: feeRateProvider, gasLimitSurchargePercent: 20)
        let service = SendEvmTransactionService(transactionData: transactionData, evmKit: evmKit, transactionService: transactionService)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory)
        let feeViewModel = EthereumFeeViewModel(service: transactionService, coinService: coinServiceFactory.baseCoinService)

        return SwapApproveConfirmationViewController(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel, delegate: delegate)
    }

}

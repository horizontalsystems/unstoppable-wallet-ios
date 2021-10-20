import UIKit
import ThemeKit
import EthereumKit

struct SwapApproveConfirmationModule {

    static func viewController(sendData: SendEvmData, dex: SwapModule.Dex, delegate: ISwapApproveDelegate?) -> UIViewController? {
        guard let platformCoin = dex.blockchain.platformCoin, let evmKit = dex.blockchain.evmKit,
              let feeRateProvider = App.shared.feeRateProviderFactory.provider(coinType: platformCoin.coinType) as? ICustomRangedFeeRateProvider else {
            return nil
        }

        let coinServiceFactory = EvmCoinServiceFactory(basePlatformCoin: platformCoin, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        let transactionService = EvmTransactionService(evmKit: evmKit, feeRateProvider: feeRateProvider, gasLimitSurchargePercent: 20)
        let service = SendEvmTransactionService(sendData: sendData, evmKit: evmKit, transactionService: transactionService, activateCoinManager: App.shared.activateCoinManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory)
        let feeViewModel = EthereumFeeViewModel(service: transactionService, coinService: coinServiceFactory.baseCoinService)

        return SwapApproveConfirmationViewController(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel, delegate: delegate)
    }

}

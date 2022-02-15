import UIKit
import ThemeKit
import EthereumKit

struct SwapApproveConfirmationModule {

    static func viewController(sendData: SendEvmData, dex: SwapModule.Dex, delegate: ISwapApproveDelegate?) -> UIViewController? {
        guard let platformCoin = dex.blockchain.platformCoin, let evmKitWrapper = dex.blockchain.evmKitWrapper else {
            return nil
        }

        let coinServiceFactory = EvmCoinServiceFactory(basePlatformCoin: platformCoin, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        let gasPriceService = EvmFeeModule.gasPriceService(evmKit: evmKitWrapper.evmKit)
        let feeService = EvmFeeService(evmKit: evmKitWrapper.evmKit, gasPriceService: gasPriceService, transactionData: sendData.transactionData, gasLimitSurchargePercent: 20)
        let service = SendEvmTransactionService(sendData: sendData, evmKitWrapper: evmKitWrapper, feeService: feeService, activateCoinManager: App.shared.activateCoinManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory())
        let feeViewModel = EvmFeeViewModel(service: feeService, gasPriceService: gasPriceService, coinService: coinServiceFactory.baseCoinService)

        return SwapApproveConfirmationViewController(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel, delegate: delegate)
    }

}

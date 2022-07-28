import UIKit
import ThemeKit
import EthereumKit

struct SwapApproveConfirmationModule {

    static func viewController(sendData: SendEvmData, dex: SwapModule.Dex, delegate: ISwapApproveDelegate?) -> UIViewController? {
        guard let evmKitWrapper = App.shared.evmBlockchainManager.evmKitManager(blockchainType: dex.blockchainType).evmKitWrapper else {
            return nil
        }

        guard let coinServiceFactory = EvmCoinServiceFactory(blockchainType: dex.blockchainType, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit) else {
            return nil
        }

        let gasPriceService = EvmFeeModule.gasPriceService(evmKit: evmKitWrapper.evmKit)
        let gasDataService = EvmGasDataService.instance(evmKit: evmKitWrapper.evmKit, blockchainType: evmKitWrapper.blockchainType, gasLimitSurchargePercent: 20)
        let feeService = EvmFeeService(evmKit: evmKitWrapper.evmKit, gasPriceService: gasPriceService, gasDataService: gasDataService, transactionData: sendData.transactionData)
        let service = SendEvmTransactionService(sendData: sendData, evmKitWrapper: evmKitWrapper, feeService: feeService, evmLabelManager: App.shared.evmLabelManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory(), evmLabelManager: App.shared.evmLabelManager)
        let feeViewModel = EvmFeeViewModel(service: feeService, gasPriceService: gasPriceService, coinService: coinServiceFactory.baseCoinService)

        return SwapApproveConfirmationViewController(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel, delegate: delegate)
    }

}

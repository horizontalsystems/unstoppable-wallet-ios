import UIKit
import ThemeKit
import EthereumKit
import OneInchKit

struct SwapConfirmationModule {

    static func viewController(sendData: SendEvmData, dex: SwapModule.Dex) -> UIViewController? {
        guard let evmKitWrapper =  App.shared.evmBlockchainManager.evmKitManager(blockchain: dex.blockchain).evmKitWrapper else {
            return nil
        }

        guard let coinServiceFactory = EvmCoinServiceFactory(evmBlockchain: dex.blockchain, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit) else {
            return nil
        }

        let gasPriceService = EvmFeeModule.gasPriceService(evmKit: evmKitWrapper.evmKit)
        let feeService = EvmFeeService(evmKit: evmKitWrapper.evmKit, gasPriceService: gasPriceService, transactionData: sendData.transactionData, gasLimitSurchargePercent: 20)
        let service = SendEvmTransactionService(sendData: sendData, evmKitWrapper: evmKitWrapper, feeService: feeService, activateCoinManager: App.shared.activateCoinManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory())
        let feeViewModel = EvmFeeViewModel(service: feeService, gasPriceService: gasPriceService, coinService: coinServiceFactory.baseCoinService)

        return SwapConfirmationViewController(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel)
    }

    static func viewController(parameters: OneInchSwapParameters, dex: SwapModule.Dex) -> UIViewController? {
        guard let evmKitWrapper =  App.shared.evmBlockchainManager.evmKitManager(blockchain: dex.blockchain).evmKitWrapper else {
            return nil
        }

        guard let swapKit = try? OneInchKit.Kit.instance(evmKit: evmKitWrapper.evmKit) else {
            return nil
        }

        let oneInchProvider = OneInchProvider(swapKit: swapKit)

        guard let coinServiceFactory = EvmCoinServiceFactory(evmBlockchain: dex.blockchain, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit) else {
            return nil
        }

        let gasPriceService = EvmFeeModule.gasPriceService(evmKit: evmKitWrapper.evmKit)
        let feeService = OneInchFeeService(evmKit: evmKitWrapper.evmKit,  provider: oneInchProvider, gasPriceService: gasPriceService, parameters: parameters)
        let service = OneInchSendEvmTransactionService(evmKitWrapper: evmKitWrapper, transactionFeeService: feeService, activateCoinManager: App.shared.activateCoinManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory())
        let feeViewModel = EvmFeeViewModel(service: feeService, gasPriceService: gasPriceService, coinService: coinServiceFactory.baseCoinService)

        return SwapConfirmationViewController(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel)
    }

}

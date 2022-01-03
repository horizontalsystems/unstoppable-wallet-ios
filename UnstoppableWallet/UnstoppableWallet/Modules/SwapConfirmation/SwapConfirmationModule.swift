import UIKit
import ThemeKit
import EthereumKit
import OneInchKit

struct SwapConfirmationModule {

    static func viewController(sendData: SendEvmData, dex: SwapModule.Dex) -> UIViewController? {
        guard let platformCoin = dex.blockchain.platformCoin, let evmKitWrapper = dex.blockchain.evmKitWrapper,
              let feeRateProvider = App.shared.feeRateProviderFactory.provider(coinType: platformCoin.coinType) as? ICustomRangedFeeRateProvider else {
            return nil
        }

        let coinServiceFactory = EvmCoinServiceFactory(basePlatformCoin: platformCoin, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        let transactionService = EvmTransactionService(evmKit: evmKitWrapper.evmKit, feeRateProvider: feeRateProvider, gasLimitSurchargePercent: 20)
        let service = SendEvmTransactionService(sendData: sendData, evmKitWrapper: evmKitWrapper, transactionService: transactionService, activateCoinManager: App.shared.activateCoinManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory)
        let feeViewModel = EthereumFeeViewModel(service: transactionService, coinService: coinServiceFactory.baseCoinService)

        return SwapConfirmationViewController(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel)
    }

    static func viewController(parameters: OneInchSwapParameters, dex: SwapModule.Dex) -> UIViewController? {
        guard let platformCoin = dex.blockchain.platformCoin,
              let evmKitWrapper = dex.blockchain.evmKitWrapper,
              let feeRateProvider = App.shared.feeRateProviderFactory.provider(coinType: platformCoin.coinType) as? ICustomRangedFeeRateProvider else {
            return nil
        }

        let swapKit = OneInchKit.Kit.instance(evmKit: evmKitWrapper.evmKit)
        let oneInchProvider = OneInchProvider(swapKit: swapKit)

        let coinServiceFactory = EvmCoinServiceFactory(basePlatformCoin: platformCoin, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        let transactionFeeService = OneInchTransactionFeeService(provider: oneInchProvider, parameters: parameters, feeRateProvider: feeRateProvider)

        let service = OneInchSendEvmTransactionService(evmKitWrapper: evmKitWrapper, transactionFeeService: transactionFeeService, activateCoinManager: App.shared.activateCoinManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory)
        let feeViewModel = EthereumFeeViewModel(service: transactionFeeService, coinService: coinServiceFactory.baseCoinService)

        return SwapConfirmationViewController(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel)
    }

}

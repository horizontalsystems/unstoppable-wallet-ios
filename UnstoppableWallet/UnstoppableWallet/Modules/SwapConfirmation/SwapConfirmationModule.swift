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
        let gasPriceService = LegacyGasPriceService(evmKit: evmKitWrapper.evmKit, feeRateProvider: feeRateProvider)
        let feeService = EvmFeeService(evmKit: evmKitWrapper.evmKit, gasPriceService: gasPriceService, transactionData: sendData.transactionData, gasLimitSurchargePercent: 20)
        let service = SendEvmTransactionService(sendData: sendData, evmKitWrapper: evmKitWrapper, feeService: feeService, activateCoinManager: App.shared.activateCoinManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory())
        let feeViewModel = EvmFeeViewModel(service: feeService, coinService: coinServiceFactory.baseCoinService)

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
        let gasPriceService = LegacyGasPriceService(evmKit: evmKitWrapper.evmKit, feeRateProvider: feeRateProvider)
        let feeService = OneInchFeeService(evmKit: evmKitWrapper.evmKit,  provider: oneInchProvider, gasPriceService: gasPriceService, parameters: parameters)

        let service = OneInchSendEvmTransactionService(evmKitWrapper: evmKitWrapper, transactionFeeService: feeService, activateCoinManager: App.shared.activateCoinManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory())
        let feeViewModel = EvmFeeViewModel(service: feeService, coinService: coinServiceFactory.baseCoinService)

        return SwapConfirmationViewController(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel)
    }

}

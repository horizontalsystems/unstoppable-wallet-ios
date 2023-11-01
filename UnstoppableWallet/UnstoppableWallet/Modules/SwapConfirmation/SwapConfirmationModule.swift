import UIKit
import ThemeKit
import EvmKit
import OneInchKit

struct SwapConfirmationModule {

    static func viewController(sendData: SendEvmData, dex: SwapModule.Dex) -> UIViewController? {
        guard let evmKitWrapper =  App.shared.evmBlockchainManager.evmKitManager(blockchainType: dex.blockchainType).evmKitWrapper else {
            return nil
        }

        guard let coinServiceFactory = EvmCoinServiceFactory(
                blockchainType: dex.blockchainType,
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                coinManager: App.shared.coinManager
        ) else {
            return nil
        }

        guard let (settingsService, settingsViewModel) = EvmSendSettingsModule.instance(
                evmKit: evmKitWrapper.evmKit, blockchainType: evmKitWrapper.blockchainType, sendData: sendData, coinServiceFactory: coinServiceFactory
        ) else {
            return nil
        }

        let service = SendEvmTransactionService(sendData: sendData, evmKitWrapper: evmKitWrapper, settingsService: settingsService, evmLabelManager: App.shared.evmLabelManager)
        let contactLabelService = ContactLabelService(contactManager: App.shared.contactManager, blockchainType: evmKitWrapper.blockchainType)
        let viewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory(), evmLabelManager: App.shared.evmLabelManager, contactLabelService: contactLabelService)

        return SwapConfirmationViewController(transactionViewModel: viewModel, settingsViewModel: settingsViewModel)
    }

    static func viewController(parameters: OneInchSwapParameters, dex: SwapModule.Dex) -> UIViewController? {
        guard let evmKitWrapper =  App.shared.evmBlockchainManager.evmKitManager(blockchainType: dex.blockchainType).evmKitWrapper else {
            return nil
        }

        let evmKit = evmKitWrapper.evmKit
        guard let apiKey = AppConfig.oneInchApiKey,
              let swapKit = try? OneInchKit.Kit.instance(evmKit: evmKit, apiKey: apiKey) else {
            return nil
        }

        let oneInchProvider = OneInchProvider(swapKit: swapKit)

        guard let coinServiceFactory = EvmCoinServiceFactory(
                blockchainType: dex.blockchainType,
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                coinManager: App.shared.coinManager
        ) else {
            return nil
        }

        let gasPriceService = EvmFeeModule.gasPriceService(evmKit: evmKit)
        let coinService = coinServiceFactory.baseCoinService
        let feeViewItemFactory = FeeViewItemFactory(scale: coinService.token.blockchainType.feePriceScale)
        let nonceService = NonceService(evmKit: evmKit, replacingNonce: nil)
        let feeService = OneInchFeeService(evmKit: evmKit,  provider: oneInchProvider, gasPriceService: gasPriceService, coinService: coinServiceFactory.baseCoinService, parameters: parameters)
        let settingsService = EvmSendSettingsService(feeService: feeService, nonceService: nonceService)

        let cautionsFactory = SendEvmCautionsFactory()
        let nonceViewModel = NonceViewModel(service: nonceService)

        let settingsViewModel: EvmSendSettingsViewModel
        switch gasPriceService {
        case let legacyService as LegacyGasPriceService:
            let feeViewModel = LegacyEvmFeeViewModel(gasPriceService: legacyService, feeService: feeService, coinService: coinService, feeViewItemFactory: feeViewItemFactory)
            settingsViewModel = EvmSendSettingsViewModel(service: settingsService, feeViewModel: feeViewModel, nonceViewModel: nonceViewModel, cautionsFactory: cautionsFactory)

        case let eip1559Service as Eip1559GasPriceService:
            let feeViewModel = Eip1559EvmFeeViewModel(gasPriceService: eip1559Service, feeService: feeService, coinService: coinService, feeViewItemFactory: feeViewItemFactory)
            settingsViewModel = EvmSendSettingsViewModel(service: settingsService, feeViewModel: feeViewModel, nonceViewModel: nonceViewModel, cautionsFactory: cautionsFactory)

        default: return nil
        }

        let transactionSettings = OneInchSendEvmTransactionService(evmKitWrapper: evmKitWrapper, oneInchFeeService: feeService, settingsService: settingsService)
        let contactLabelService = ContactLabelService(contactManager: App.shared.contactManager, blockchainType: evmKitWrapper.blockchainType)
        let transactionViewModel = SendEvmTransactionViewModel(service: transactionSettings, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory(), evmLabelManager: App.shared.evmLabelManager, contactLabelService: contactLabelService)

        return SwapConfirmationViewController(transactionViewModel: transactionViewModel, settingsViewModel: settingsViewModel)
    }

}

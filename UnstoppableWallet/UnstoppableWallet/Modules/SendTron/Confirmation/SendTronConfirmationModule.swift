import Foundation
import HsExtensions
import MarketKit
import ThemeKit
import TronKit
import UIKit

enum SendTronConfirmationModule {
    static func viewController(tronKitWrapper: TronKitWrapper, contract: Contract) -> UIViewController? {
        guard let coinServiceFactory = EvmCoinServiceFactory(
            blockchainType: .tron,
            marketKit: App.shared.marketKit,
            currencyManager: App.shared.currencyManager,
            coinManager: App.shared.coinManager
        ) else {
            return nil
        }

        let switchService = AmountTypeSwitchService(userDefaultsStorage: App.shared.userDefaultsStorage)
        let feeFiatService = FiatService(switchService: switchService, currencyManager: App.shared.currencyManager, marketKit: App.shared.marketKit)
        let feeService = SendFeeService(fiatService: feeFiatService, feeToken: coinServiceFactory.baseCoinService.token)
        let feeViewModel = SendFeeViewModel(service: feeService)

        let service = SendTronConfirmationService(contract: contract, tronKitWrapper: tronKitWrapper, feeService: feeService, evmLabelManager: App.shared.evmLabelManager)
        let contactLabelService = ContactLabelService(contactManager: App.shared.contactManager, blockchainType: .tron)
        let viewModel = SendTronConfirmationViewModel(service: service, coinServiceFactory: coinServiceFactory, evmLabelManager: App.shared.evmLabelManager, contactLabelService: contactLabelService)
        let controller = SendTronConfirmationViewController(transactionViewModel: viewModel, feeViewModel: feeViewModel)

        return controller
    }
}

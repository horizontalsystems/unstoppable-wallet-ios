import Foundation
import HsExtensions
import MarketKit

import TronKit
import UIKit

enum SendTronConfirmationModule {
    static func viewController(tronKitWrapper: TronKitWrapper, contract: Contract) -> UIViewController? {
        guard let coinServiceFactory = EvmCoinServiceFactory(
            blockchainType: .tron,
            marketKit: Core.shared.marketKit,
            currencyManager: Core.shared.currencyManager,
            coinManager: Core.shared.coinManager
        ) else {
            return nil
        }

        let switchService = AmountTypeSwitchService(userDefaultsStorage: Core.shared.userDefaultsStorage)
        let feeFiatService = FiatService(switchService: switchService, currencyManager: Core.shared.currencyManager, marketKit: Core.shared.marketKit)
        let feeService = SendFeeService(fiatService: feeFiatService, feeToken: coinServiceFactory.baseCoinService.token)
        let feeViewModel = SendFeeViewModel(service: feeService)

        let service = SendTronConfirmationService(contract: contract, tronKitWrapper: tronKitWrapper, feeService: feeService, evmLabelManager: Core.shared.evmLabelManager)
        let contactLabelService = ContactLabelService(contactManager: Core.shared.contactManager, blockchainType: .tron)
        let viewModel = SendTronConfirmationViewModel(service: service, coinServiceFactory: coinServiceFactory, evmLabelManager: Core.shared.evmLabelManager, contactLabelService: contactLabelService)
        let controller = SendTronConfirmationViewController(transactionViewModel: viewModel, feeViewModel: feeViewModel)

        return controller
    }
}

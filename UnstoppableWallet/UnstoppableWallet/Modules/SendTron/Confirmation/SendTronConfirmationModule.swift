import Foundation
import UIKit
import ThemeKit
import TronKit
import MarketKit
import HsExtensions
import StorageKit

struct SendTronConfirmationModule {

    static func viewController(tronKitWrapper: TronKitWrapper, contract: Contract) -> UIViewController? {
        guard let coinServiceFactory = EvmCoinServiceFactory(
            blockchainType: .tron,
            marketKit: App.shared.marketKit,
            currencyKit: App.shared.currencyKit,
            coinManager: App.shared.coinManager
        ) else {
            return nil
        }

        let switchService = AmountTypeSwitchService(localStorage: StorageKit.LocalStorage.default)
        let feeFiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let feeService = SendFeeService(fiatService: feeFiatService, feeToken: coinServiceFactory.baseCoinService.token)
        let feeViewModel = SendFeeViewModel(service: feeService)

        let service = SendTronConfirmationService(contract: contract, tronKitWrapper: tronKitWrapper, feeService: feeService, evmLabelManager: App.shared.evmLabelManager)
        let contactLabelService = ContactLabelService(contactManager: App.shared.contactManager, blockchainType: .tron)
        let viewModel = SendTronConfirmationViewModel(service: service, coinServiceFactory: coinServiceFactory, evmLabelManager: App.shared.evmLabelManager, contactLabelService: contactLabelService)
        let controller = SendTronConfirmationViewController(transactionViewModel: viewModel, feeViewModel: feeViewModel)

        return controller
    }

}

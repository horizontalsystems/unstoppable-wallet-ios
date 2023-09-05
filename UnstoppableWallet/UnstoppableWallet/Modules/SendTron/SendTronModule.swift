import UIKit
import ThemeKit
import MarketKit
import StorageKit

class SendTronModule {

    static func viewController(token: Token, mode: SendBaseService.Mode, adapter: ISendTronAdapter) -> UIViewController {
        let tronAddressParserItem = TronAddressParser()
        let addressParserChain = AddressParserChain().append(handler: tronAddressParserItem)

        let addressService = AddressService(
            mode: .parsers(AddressParserFactory.parser(blockchainType: .tron), addressParserChain),
            marketKit: App.shared.marketKit,
            contactBookManager: App.shared.contactManager,
            blockchainType: .tron
        )

        let service = SendTronService(token: token, mode: mode, adapter: adapter, addressService: addressService)
        let switchService = AmountTypeSwitchService(localStorage: StorageKit.LocalStorage.default)
        let fiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)

        switchService.add(toggleAllowedObservable: fiatService.toggleAvailableObservable)

        let coinService = CoinService(token: token, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)

        let viewModel = SendTronViewModel(service: service)
        let availableBalanceViewModel = SendAvailableBalanceViewModel(service: service, coinService: coinService, switchService: switchService)

        let amountViewModel = AmountInputViewModel(
            service: service,
            fiatService: fiatService,
            switchService: switchService,
            decimalParser: AmountDecimalParser()
        )
        addressService.amountPublishService = amountViewModel

        let recipientViewModel = TronRecipientAddressViewModel(service: addressService, handlerDelegate: nil, sendService: service)

        let viewController = SendTronViewController(
            tronKitWrapper: adapter.tronKitWrapper,
            viewModel: viewModel,
            availableBalanceViewModel: availableBalanceViewModel,
            amountViewModel: amountViewModel,
            recipientViewModel: recipientViewModel
        )

        return viewController
    }

}

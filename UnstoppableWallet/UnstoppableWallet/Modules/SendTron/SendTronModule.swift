import MarketKit

import UIKit

enum SendTronModule {
    static func viewController(token: Token, mode: PreSendViewModel.Mode, adapter: ISendTronAdapter) -> UIViewController {
        let tronAddressParserItem = TronAddressParser()
        let addressParserChain = AddressParserChain().append(handler: tronAddressParserItem)

        let addressService = AddressService(
            mode: .parsers(AddressParserFactory.parser(blockchainType: .tron, tokenType: token.type), addressParserChain),
            marketKit: Core.shared.marketKit,
            contactBookManager: Core.shared.contactManager,
            blockchainType: .tron,
        )
        let memoService = SendMemoInputService(maxSymbols: 120)

        let service = SendTronService(
            token: token,
            mode: mode,
            adapter: adapter,
            addressService: addressService,
            memoService: memoService
        )
        let switchService = AmountTypeSwitchService(userDefaultsStorage: Core.shared.userDefaultsStorage)
        let fiatService = FiatService(switchService: switchService, currencyManager: Core.shared.currencyManager, marketKit: Core.shared.marketKit)

        switchService.add(toggleAllowedObservable: fiatService.toggleAvailableObservable)

        let coinService = CoinService(token: token, currencyManager: Core.shared.currencyManager, marketKit: Core.shared.marketKit)

        let viewModel = SendTronViewModel(service: service)
        let availableBalanceViewModel = SendAvailableBalanceViewModel(service: service, coinService: coinService, switchService: switchService)

        let amountViewModel = AmountInputViewModel(
            service: service,
            fiatService: fiatService,
            switchService: switchService,
            decimalParser: AmountDecimalParser()
        )
        addressService.amountPublishService = amountViewModel
        memoService.availableService = service

        let recipientViewModel = TronRecipientAddressViewModel(service: addressService, handlerDelegate: nil, sendService: service)
        let memoViewModel = SendMemoInputViewModel(service: memoService)

        let viewController = SendTronViewController(
            tronKitWrapper: adapter.tronKitWrapper,
            viewModel: viewModel,
            availableBalanceViewModel: availableBalanceViewModel,
            amountViewModel: amountViewModel,
            recipientViewModel: recipientViewModel,
            memoViewModel: memoViewModel
        )

        return viewController
    }
}

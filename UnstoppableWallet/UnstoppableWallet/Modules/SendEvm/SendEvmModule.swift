import UIKit
import ThemeKit
import MarketKit
import StorageKit

class SendEvmModule {

    static func viewController(token: Token, mode: SendBaseService.Mode, adapter: ISendEthereumAdapter) -> UIViewController {
        let evmAddressParserItem = EvmAddressParser()
        let udnAddressParserItem = UdnAddressParserItem.item(rawAddressParserItem: evmAddressParserItem, coinCode: token.coin.code, token: token)

        let addressParserChain = AddressParserChain()
                .append(handler: evmAddressParserItem)
                .append(handler: udnAddressParserItem)

        if let httpSyncSource = App.shared.evmSyncSourceManager.httpSyncSource(blockchainType: .ethereum),
           let ensAddressParserItem = EnsAddressParserItem(rpcSource: httpSyncSource.rpcSource, rawAddressParserItem: evmAddressParserItem) {
            addressParserChain.append(handler: ensAddressParserItem)
        }

        let addressUriParser = AddressParserFactory.parser(blockchainType: token.blockchainType)
        let addressService = AddressService(
                mode: .parsers(addressUriParser, addressParserChain),
                marketKit: App.shared.marketKit,
                contactBookManager: App.shared.contactManager,
                blockchainType: token.blockchainType
        )

        let service = SendEvmService(token: token, mode: mode, adapter: adapter, addressService: addressService)

        let switchService = AmountTypeSwitchService(localStorage: StorageKit.LocalStorage.default)
        let fiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)

        switchService.add(toggleAllowedObservable: fiatService.toggleAvailableObservable)

        let coinService = CoinService(token: token, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)

        let viewModel = SendEvmViewModel(service: service)
        let availableBalanceViewModel = SendAvailableBalanceViewModel(service: service, coinService: coinService, switchService: switchService)

        let amountViewModel = AmountInputViewModel(
                service: service,
                fiatService: fiatService,
                switchService: switchService,
                decimalParser: AmountDecimalParser()
        )
        addressService.amountPublishService = amountViewModel

        let recipientViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)

        let viewController = SendEvmViewController(
                evmKitWrapper: adapter.evmKitWrapper,
                viewModel: viewModel,
                availableBalanceViewModel: availableBalanceViewModel,
                amountViewModel: amountViewModel,
                recipientViewModel: recipientViewModel
        )

        return viewController
    }

}

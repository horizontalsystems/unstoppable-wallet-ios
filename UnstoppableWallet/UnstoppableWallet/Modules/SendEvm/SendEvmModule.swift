import UIKit
import ThemeKit
import MarketKit
import StorageKit

class SendEvmModule {

    static func viewController(platformCoin: PlatformCoin, adapter: ISendEthereumAdapter) -> UIViewController {
        let addressParserChain = AddressParserChain()
        addressParserChain.append(handler: EvmAddressParser())

        let service = SendEvmService(platformCoin: platformCoin, adapter: adapter, addressParserChain: addressParserChain)
        let switchService = AmountTypeSwitchService(localStorage: StorageKit.LocalStorage.default)
        let fiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)

        switchService.add(toggleAllowedObservable: fiatService.toggleAvailableObservable)

        let coinService = CoinService(platformCoin: platformCoin, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)

        let viewModel = SendEvmViewModel(service: service)
        let availableBalanceViewModel = SendAvailableBalanceViewModel(service: service, coinService: coinService, switchService: switchService)

        let amountViewModel = AmountInputViewModel(
                service: service,
                fiatService: fiatService,
                switchService: switchService,
                decimalParser: AmountDecimalParser()
        )

        let chainCoinCode = AddressResolutionService.chainCoinCode(coinType: platformCoin.platform.coinType) ?? platformCoin.code
        addressParserChain.append(handler: UDNAddressParserItem(coinCode: chainCoinCode, chain: nil))

        let recipientViewModel = RecipientAddressViewModel(
                service: service,
                addressParser: AddressParserFactory.parser(coinType: platformCoin.coinType)
        )

        let viewController = SendEvmViewController(
                evmKit: adapter.evmKit,
                viewModel: viewModel,
                availableBalanceViewModel: availableBalanceViewModel,
                amountViewModel: amountViewModel,
                recipientViewModel: recipientViewModel
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}

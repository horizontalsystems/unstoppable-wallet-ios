import UIKit
import ThemeKit
import MarketKit
import StorageKit

class SendEvmModule {

    static func viewController(platformCoin: PlatformCoin, adapter: ISendEthereumAdapter) -> UIViewController {
        let service = SendEvmService(platformCoin: platformCoin, adapter: adapter)
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
        let resolutionService = AddressResolutionService(
                coinCode: chainCoinCode,
                chain: nil
        )

        let addressParserFactory = AddressParserFactory()
        let recipientViewModel = RecipientAddressViewModel(
                service: service,
                resolutionService: resolutionService,
                addressParser: addressParserFactory.parser(coinType: platformCoin.coinType)
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

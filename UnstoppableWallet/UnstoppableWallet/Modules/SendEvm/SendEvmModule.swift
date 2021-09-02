import UIKit
import ThemeKit
import MarketKit

class SendEvmModule {

    static func viewController(platformCoin: PlatformCoin, adapter: ISendEthereumAdapter) -> UIViewController {
        let service = SendEvmService(platformCoin: platformCoin, adapter: adapter)
        let switchService = AmountTypeSwitchService()
        let fiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManagerNew)

        switchService.add(toggleAllowedObservable: fiatService.toggleAvailableObservable)

        let coinService = CoinService(platformCoin: platformCoin, currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManagerNew)

        let viewModel = SendEvmViewModel(service: service)
        let availableBalanceViewModel = SendAvailableBalanceViewModel(service: service, coinService: coinService)

        let amountViewModel = AmountInputViewModel(
                service: service,
                fiatService: fiatService,
                switchService: switchService,
                decimalParser: AmountDecimalParser()
        )

        let addressParserFactory = AddressParserFactory()
        let recipientViewModel = RecipientAddressViewModel(
                service: service,
                resolutionService: AddressResolutionService(coinCode: platformCoin.coin.code),
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

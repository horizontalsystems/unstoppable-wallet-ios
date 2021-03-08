import UIKit
import ThemeKit
import CoinKit

class SendEvmModule {

    static func viewController(coin: Coin, adapter: ISendEthereumAdapter) -> UIViewController {
        let service = SendEvmService(coin: coin, adapter: adapter)
        let switchService = AmountTypeSwitchService()
        let fiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManager)

        switchService.add(toggleAllowedObservable: fiatService.toggleAvailableObservable)

        let coinService = CoinService(coin: coin, currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManager)

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
                resolutionService: AddressResolutionService(coinCode: coin.code),
                addressParser: addressParserFactory.parser(coin: coin)
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

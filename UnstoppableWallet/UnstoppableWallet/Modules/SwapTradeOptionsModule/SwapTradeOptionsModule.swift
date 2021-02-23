import UIKit
import ThemeKit

struct SwapTradeOptionsModule {

    static func viewController(tradeService: SwapTradeService) -> UIViewController? {
        guard let ethereumCoin = App.shared.coinKit.coin(type: .ethereum) else {
            return nil
        }

        let addressParserFactory = AddressParserFactory()

        let service = SwapTradeOptionsService(tradeOptions: tradeService.swapTradeOptions)
        let viewModel = SwapTradeOptionsViewModel(service: service, tradeService: tradeService, decimalParser: AmountDecimalParser())

        let recipientViewModel = RecipientAddressViewModel(
                service: service,
                resolutionService: AddressResolutionService(coinCode: ethereumCoin.code),
                addressParser: addressParserFactory.parser(coin: ethereumCoin)
        )
        let slippageViewModel = SwapSlippageViewModel(service: service, decimalParser: AmountDecimalParser())
        let deadlineViewModel = SwapDeadlineViewModel(service: service, decimalParser: AmountDecimalParser())

        let viewController = SwapTradeOptionsView(viewModel: viewModel, recipientViewModel: recipientViewModel, slippageViewModel: slippageViewModel, deadlineViewModel: deadlineViewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}

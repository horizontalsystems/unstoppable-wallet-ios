import UIKit
import ThemeKit

struct UniswapSettingsModule {

    static func dataSource(tradeService: UniswapTradeService) -> ISwapSettingsDataSource? {
        guard let ethereumCoin = App.shared.coinKit.coin(type: .ethereum) else {
            return nil
        }

        let addressParserFactory = AddressParserFactory()

        let service = UniswapSettingsService(tradeOptions: tradeService.swapTradeOptions)
        let viewModel = UniswapSettingsViewModel(service: service, tradeService: tradeService, decimalParser: AmountDecimalParser())

        let recipientViewModel = RecipientAddressViewModel(
                service: service,
                resolutionService: AddressResolutionService(coinCode: ethereumCoin.code),
                addressParser: addressParserFactory.parser(coin: ethereumCoin)
        )
        let slippageViewModel = SwapSlippageViewModel(service: service, decimalParser: AmountDecimalParser())
        let deadlineViewModel = SwapDeadlineViewModel(service: service, decimalParser: AmountDecimalParser())

        return UniswapSettingsDataSource(
                viewModel: viewModel,
                recipientViewModel: recipientViewModel,
                slippageViewModel: slippageViewModel,
                deadlineViewModel: deadlineViewModel
        )
    }

}

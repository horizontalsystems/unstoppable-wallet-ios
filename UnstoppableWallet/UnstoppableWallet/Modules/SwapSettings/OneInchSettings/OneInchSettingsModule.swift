import UIKit
import ThemeKit

struct OneInchSettingsModule {

    static func dataSource(tradeService: OneInchTradeService) -> ISwapSettingsDataSource? {
        guard let ethereumCoin = App.shared.coinKit.coin(type: .ethereum) else {
            return nil
        }

        let addressParserFactory = AddressParserFactory()

        let service = OneInchSettingsService(settings: tradeService.settings)
        let viewModel = OneInchSettingsViewModel(service: service, tradeService: tradeService, decimalParser: AmountDecimalParser())

        let recipientViewModel = RecipientAddressViewModel(
                service: service,
                resolutionService: AddressResolutionService(coinCode: ethereumCoin.code),
                addressParser: addressParserFactory.parser(coin: ethereumCoin)
        )
        let slippageViewModel = SwapSlippageViewModel(service: service, decimalParser: AmountDecimalParser())

        return OneInchSettingsDataSource(
                viewModel: viewModel,
                recipientViewModel: recipientViewModel,
                slippageViewModel: slippageViewModel
        )
    }

}

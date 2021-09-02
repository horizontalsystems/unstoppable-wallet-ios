import UIKit
import ThemeKit

struct OneInchSettingsModule {

    static func dataSource(tradeService: OneInchTradeService) -> ISwapSettingsDataSource? {
        guard let ethereumPlatformCoin = try? App.shared.marketKit.platformCoin(coinType: .ethereum) else {
            return nil
        }

        let addressParserFactory = AddressParserFactory()

        let service = OneInchSettingsService(settings: tradeService.settings)
        let viewModel = OneInchSettingsViewModel(service: service, tradeService: tradeService, decimalParser: AmountDecimalParser())

        let recipientViewModel = RecipientAddressViewModel(
                service: service,
                resolutionService: AddressResolutionService(coinCode: ethereumPlatformCoin.coin.code),
                addressParser: addressParserFactory.parser(coinType: ethereumPlatformCoin.coinType)
        )
        let slippageViewModel = SwapSlippageViewModel(service: service, decimalParser: AmountDecimalParser())

        return OneInchSettingsDataSource(
                viewModel: viewModel,
                recipientViewModel: recipientViewModel,
                slippageViewModel: slippageViewModel
        )
    }

}

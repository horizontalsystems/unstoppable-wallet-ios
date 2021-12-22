import UIKit
import ThemeKit

struct OneInchSettingsModule {

    static func dataSource(tradeService: OneInchTradeService) -> ISwapSettingsDataSource? {
        guard let ethereumPlatformCoin = try? App.shared.marketKit.platformCoin(coinType: .ethereum) else {
            return nil
        }
        let chainCoinCode = tradeService.platformCoinIn.flatMap { AddressResolutionService.chainCoinCode(coinType: $0.coinType) } ?? ethereumPlatformCoin.code

        let addressParserChain = AddressParserChain(address: tradeService.settings.recipient)
                    .append(handler: EvmAddressParser())
                    .append(handler: UDNAddressParserItem(coinCode: chainCoinCode, chain: nil))

        let service = OneInchSettingsService(settings: tradeService.settings, addressParserChain: addressParserChain)
        let viewModel = OneInchSettingsViewModel(service: service, tradeService: tradeService, decimalParser: AmountDecimalParser())

        let recipientViewModel = RecipientAddressViewModel(
                service: service,
                addressParser: AddressParserFactory.parser(coinType: ethereumPlatformCoin.coinType)
        )
        let slippageViewModel = SwapSlippageViewModel(service: service, decimalParser: AmountDecimalParser())

        return OneInchSettingsDataSource(
                viewModel: viewModel,
                recipientViewModel: recipientViewModel,
                slippageViewModel: slippageViewModel
        )
    }

}

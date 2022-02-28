import UIKit
import ThemeKit

struct OneInchSettingsModule {

    static func dataSource(tradeService: OneInchTradeService) -> ISwapSettingsDataSource? {
        guard let ethereumPlatformCoin = try? App.shared.marketKit.platformCoin(coinType: .ethereum) else {
            return nil
        }
        let platformCoin = tradeService.platformCoinIn

        let coinCode = platformCoin?.code ?? ethereumPlatformCoin.code
        let chainCoinCode = platformCoin.flatMap { UDNAddressParserItem.chainCoinCode(coinType: $0.platform.coinType) }
        let chain = platformCoin.flatMap { UDNAddressParserItem.chain(coinType: $0.platform.coinType) }

        let addressParserChain = AddressParserChain()
                    .append(handler: EvmAddressParser())
                    .append(handler: UDNAddressParserItem(coinCode: coinCode, platformCoinCode: chainCoinCode, chain: chain))

        let addressUriParser = AddressParserFactory.parser(coinType: ethereumPlatformCoin.coinType)
        let addressService = AddressService(addressUriParser: addressUriParser, addressParserChain: addressParserChain, initialAddress: tradeService.settings.recipient)

        let service = OneInchSettingsService(settings: tradeService.settings, addressService: addressService)
        let viewModel = OneInchSettingsViewModel(service: service, tradeService: tradeService, decimalParser: AmountDecimalParser())

        let recipientViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)
        let slippageViewModel = SwapSlippageViewModel(service: service, decimalParser: AmountDecimalParser())

        return OneInchSettingsDataSource(
                viewModel: viewModel,
                recipientViewModel: recipientViewModel,
                slippageViewModel: slippageViewModel
        )
    }

}

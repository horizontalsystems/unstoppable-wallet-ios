import UIKit
import ThemeKit

struct UniswapSettingsModule {

    static func dataSource(tradeService: UniswapTradeService) -> ISwapSettingsDataSource? {
        guard let ethereumPlatformCoin = try? App.shared.marketKit.platformCoin(coinType: .ethereum) else {
            return nil
        }
        let platformCoin = tradeService.platformCoinIn

        let coinCode = platformCoin?.code ?? ethereumPlatformCoin.code

        let evmAddressParserItem = EvmAddressParser()
        let udnAddressParserItem = UDNAddressParserItem.item(rawAddressParserItem: evmAddressParserItem, coinCode: coinCode, coinType: platformCoin?.coinType)
        let addressParserChain = AddressParserChain()
                .append(handler: evmAddressParserItem)
                .append(handler: udnAddressParserItem)

        let addressUriParser = AddressParserFactory.parser(coinType: ethereumPlatformCoin.coinType)
        let addressService = AddressService(addressUriParser: addressUriParser, addressParserChain: addressParserChain, initialAddress: tradeService.settings.recipient)

        let service = UniswapSettingsService(tradeOptions: tradeService.settings, addressService: addressService)
        let viewModel = UniswapSettingsViewModel(service: service, tradeService: tradeService)

        let recipientViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)
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

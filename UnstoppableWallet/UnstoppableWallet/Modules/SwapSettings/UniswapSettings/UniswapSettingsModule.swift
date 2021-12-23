import UIKit
import ThemeKit

struct UniswapSettingsModule {

    static func dataSource(tradeService: UniswapTradeService) -> ISwapSettingsDataSource? {
        guard let ethereumPlatformCoin = try? App.shared.marketKit.platformCoin(coinType: .ethereum) else {
            return nil
        }
        let chainCoinCode = tradeService.platformCoinIn.flatMap { AddressResolutionService.chainCoinCode(coinType: $0.coinType) } ?? ethereumPlatformCoin.code

        let addressParserChain = AddressParserChain()
                .append(handler: EvmAddressParser())
                .append(handler: UDNAddressParserItem(coinCode: chainCoinCode, chain: nil))

        let addressUriParser = AddressParserFactory.parser(coinType: ethereumPlatformCoin.coinType)
        let addressService = AddressService(addressUriParser: addressUriParser, addressParserChain: addressParserChain, initialAddress: tradeService.settings.recipient)

        let service = UniswapSettingsService(tradeOptions: tradeService.settings, addressService: addressService)
        let viewModel = UniswapSettingsViewModel(service: service, tradeService: tradeService, decimalParser: AmountDecimalParser())

        let recipientViewModel = RecipientAddressViewModel(service: addressService)
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

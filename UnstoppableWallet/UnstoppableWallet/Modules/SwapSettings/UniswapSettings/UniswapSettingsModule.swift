import UIKit
import ThemeKit

struct UniswapSettingsModule {

    static func dataSource(tradeService: UniswapTradeService) -> ISwapSettingsDataSource? {
        guard let ethereumPlatformCoin = try? App.shared.marketKit.platformCoin(coinType: .ethereum) else {
            return nil
        }
        let chainCoinCode = tradeService.platformCoinIn.flatMap { AddressResolutionService.chainCoinCode(coinType: $0.coinType) } ?? ethereumPlatformCoin.code

        let addressParserChain = AddressParserChain(address: tradeService.settings.recipient)
                .append(handler: EvmAddressParser())
                .append(handler: UDNAddressParserItem(coinCode: chainCoinCode, chain: nil))

        let service = UniswapSettingsService(tradeOptions: tradeService.settings, addressParserChain: addressParserChain)
        let viewModel = UniswapSettingsViewModel(service: service, tradeService: tradeService, decimalParser: AmountDecimalParser())

        let recipientViewModel = RecipientAddressViewModel(
                service: service,
                addressParser: AddressParserFactory.parser(coinType: ethereumPlatformCoin.coinType)
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

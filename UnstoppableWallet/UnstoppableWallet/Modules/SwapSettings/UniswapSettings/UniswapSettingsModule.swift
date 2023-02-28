import UIKit
import ThemeKit
import MarketKit

struct UniswapSettingsModule {

    static func dataSource(tradeService: UniswapTradeService) -> ISwapSettingsDataSource? {
        guard let ethereumToken = try? App.shared.marketKit.token(query: TokenQuery(blockchainType: .ethereum, tokenType: .native)) else {
            return nil
        }
        let token = tradeService.tokenIn

        let coinCode = token?.coin.code ?? ethereumToken.coin.code

        let evmAddressParserItem = EvmAddressParser()
        let udnAddressParserItem = UdnAddressParserItem.item(rawAddressParserItem: evmAddressParserItem, coinCode: coinCode, token: token)
        let addressParserChain = AddressParserChain()
                .append(handler: evmAddressParserItem)
                .append(handler: udnAddressParserItem)

        if let httpSyncSource = App.shared.evmSyncSourceManager.httpSyncSource(blockchainType: .ethereum),
           let ensAddressParserItem = EnsAddressParserItem(rpcSource: httpSyncSource.rpcSource, rawAddressParserItem: evmAddressParserItem) {
            addressParserChain.append(handler: ensAddressParserItem)
        }

        let addressUriParser = AddressParserFactory.parser(blockchainType: ethereumToken.blockchainType)
        let addressService = AddressService(mode: .parsers(addressUriParser, addressParserChain), initialAddress: tradeService.settings.recipient)

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

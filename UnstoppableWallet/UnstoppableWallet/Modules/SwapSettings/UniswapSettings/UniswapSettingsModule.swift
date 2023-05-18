import UIKit
import ThemeKit
import MarketKit

protocol ISwapSettingProvider: AnyObject {
    var tokenIn: Token? { get }
    var settings: UniswapSettings { get set }
}

struct UniswapSettingsModule {

    static func dataSource(settingProvider: ISwapSettingProvider, showDeadline: Bool) -> ISwapSettingsDataSource? {
        guard let ethereumToken = try? App.shared.marketKit.token(query: TokenQuery(blockchainType: .ethereum, tokenType: .native)) else {
            return nil
        }
        let token = settingProvider.tokenIn

        let coinCode = token?.coin.code ?? ethereumToken.coin.code
        let blockchainType = token?.blockchainType ?? ethereumToken.blockchainType

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
        let addressService = AddressService(mode: .parsers(addressUriParser, addressParserChain), marketKit: App.shared.marketKit, contactBookManager: App.shared.contactManager, blockchainType: blockchainType, initialAddress: settingProvider.settings.recipient)

        let service = UniswapSettingsService(tradeOptions: settingProvider.settings, addressService: addressService)
        let viewModel = UniswapSettingsViewModel(service: service, settingProvider: settingProvider)

        let recipientViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)
        let slippageViewModel = SwapSlippageViewModel(service: service, decimalParser: AmountDecimalParser())

        let deadlineViewModel: SwapDeadlineViewModel? = showDeadline ?
                .init(service: service, decimalParser: AmountDecimalParser()) :
                nil

        return UniswapSettingsDataSource(
                viewModel: viewModel,
                recipientViewModel: recipientViewModel,
                slippageViewModel: slippageViewModel,
                deadlineViewModel: deadlineViewModel
        )
    }

}


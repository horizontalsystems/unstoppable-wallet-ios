import MarketKit
import ThemeKit
import UIKit

struct WatchModule {
    static func viewController(sourceViewController: UIViewController? = nil) -> UIViewController {
        let ethereumToken = try? App.shared.marketKit.token(query: TokenQuery(blockchainType: .ethereum, tokenType: .native))

        let evmAddressParserItem = EvmAddressParser()
        let udnAddressParserItem = UdnAddressParserItem.item(rawAddressParserItem: evmAddressParserItem, coinCode: "ETH", token: ethereumToken)
        let addressParserChain = AddressParserChain()
            .append(handler: evmAddressParserItem)
            .append(handler: udnAddressParserItem)

        if let httpSyncSource = App.shared.evmSyncSourceManager.httpSyncSource(blockchainType: .ethereum),
           let ensAddressParserItem = EnsAddressParserItem(rpcSource: httpSyncSource.rpcSource, rawAddressParserItem: evmAddressParserItem) {
            addressParserChain.append(handler: ensAddressParserItem)
        }

        let addressUriParser = AddressParserFactory.parser(blockchainType: .ethereum)
        let addressService = AddressService(mode: .parsers(addressUriParser, addressParserChain), marketKit: App.shared.marketKit, contactBookManager: nil, blockchainType: .ethereum)

        let evmAddressService = WatchEvmAddressService(addressService: addressService)
        let evmAddressViewModel = WatchEvmAddressViewModel(service: evmAddressService)

        let tronAddressParserChain = AddressParserChain().append(handler: TronAddressParser())
        let tronAddressService = AddressService(
            mode: .parsers(AddressParserFactory.parser(blockchainType: .tron), tronAddressParserChain),
            marketKit: App.shared.marketKit, contactBookManager: nil, blockchainType: .tron
        )
        let watchTronAddressService = WatchTronAddressService(addressService: tronAddressService)
        let tronAddressViewModel = WatchTronAddressViewModel(service: watchTronAddressService)

        let publicKeyService = WatchPublicKeyService()
        let publicKeyViewModel = WatchPublicKeyViewModel(service: publicKeyService)

        let service = WatchService(accountFactory: App.shared.accountFactory)
        let tronService = WatchTronService(accountFactory: App.shared.accountFactory, accountManager: App.shared.accountManager,
                                           walletManager: App.shared.walletManager, marketKit: App.shared.marketKit)
        let viewModel = WatchViewModel(
            service: service,
            tronService: tronService,
            evmAddressViewModel: evmAddressViewModel,
            tronAddressViewModel: tronAddressViewModel,
            publicKeyViewModel: publicKeyViewModel
        )

        let evmRecipientAddressViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)
        let tronRecipientAddressViewModel = RecipientAddressViewModel(service: tronAddressService, handlerDelegate: nil)

        let viewController = WatchViewController(
            viewModel: viewModel,
            evmAddressViewModel: evmRecipientAddressViewModel,
            tronAddressViewModel: tronRecipientAddressViewModel,
            publicKeyViewModel: publicKeyViewModel,
            sourceViewController: sourceViewController
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

    static func viewController(sourceViewController: UIViewController? = nil, watchType: WatchType, accountType: AccountType, name: String) -> UIViewController? {
        let service: IChooseWatchService

        switch watchType {
        case .evmAddress:
            service = ChooseBlockchainService(
                accountType: accountType,
                accountName: name,
                accountFactory: App.shared.accountFactory,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager,
                evmBlockchainManager: App.shared.evmBlockchainManager,
                marketKit: App.shared.marketKit
            )

        case .tronAddress:
            return nil

        case .publicKey:
            service = ChooseCoinService(
                accountType: accountType,
                accountName: name,
                accountFactory: App.shared.accountFactory,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager,
                marketKit: App.shared.marketKit
            )
        }

        let viewModel = ChooseWatchViewModel(service: service, watchType: watchType)

        return ChooseWatchViewController(viewModel: viewModel, sourceViewController: sourceViewController)
    }
}

extension WatchModule {
    enum WatchType: CaseIterable {
        case evmAddress
        case tronAddress
        case publicKey

        var title: String {
            switch self {
            case .evmAddress: return "watch_address.evm_address".localized
            case .tronAddress: return "watch_address.tron_address".localized
            case .publicKey: return "watch_address.public_key".localized
            }
        }

        var subtitle: String {
            switch self {
            case .evmAddress: return "(Ethereum, Binance, …)"
            case .tronAddress: return "(TRX, Tron tokens, …)"
            case .publicKey: return "(Bitcoin, Litecoin, …)"
            }
        }
    }

    enum Item {
        case coin(token: Token)
        case blockchain(blockchain: Blockchain)
    }
}

import MarketKit
import ThemeKit
import UIKit

enum WatchModule {
    static func viewController(sourceViewController: UIViewController? = nil) -> UIViewController {
        let addressParserChain = AddressParserChain()
        addressParserChain.append(handlers:
            AddressParserFactory.parserChainHandlers(blockchainType: .ethereum, withEns: true)
                + BtcBlockchainManager.blockchainTypes.flatMap {
                    AddressParserFactory.parserChainHandlers(blockchainType: $0, withEns: false)
                }
                + AddressParserFactory.parserChainHandlers(blockchainType: .tron)
                + AddressParserFactory.parserChainHandlers(blockchainType: .ton)
        )

        let service = WatchService(
            accountFactory: App.shared.accountFactory,
            addressParserChain: addressParserChain,
            uriParser: AddressParserFactory.parser(blockchainType: nil, tokenType: nil)
        )
        let viewModel = WatchViewModel(service: service)
        let viewController = WatchViewController(viewModel: viewModel, sourceViewController: sourceViewController)

        return ThemeNavigationController(rootViewController: viewController)
    }

    static func viewController(sourceViewController: UIViewController? = nil, accountType: AccountType, name: String) -> UIViewController? {
        let service = ChooseWatchService(
            accountType: accountType,
            accountName: name,
            accountFactory: App.shared.accountFactory,
            accountManager: App.shared.accountManager,
            walletManager: App.shared.walletManager,
            marketKit: App.shared.marketKit,
            evmBlockchainManager: App.shared.evmBlockchainManager
        )

        if case let .coins(tokens) = service.items, tokens.count <= 1 {
            return nil
        } else {
            let viewModel = ChooseWatchViewModel(service: service)

            return ChooseWatchViewController(viewModel: viewModel, sourceViewController: sourceViewController)
        }
    }

    static func watch(accountType: AccountType, name: String) {
        let service = ChooseWatchService(
            accountType: accountType,
            accountName: name,
            accountFactory: App.shared.accountFactory,
            accountManager: App.shared.accountManager,
            walletManager: App.shared.walletManager,
            marketKit: App.shared.marketKit,
            evmBlockchainManager: App.shared.evmBlockchainManager
        )

        if case let .coins(tokens) = service.items, tokens.count <= 1 {
            service.watch(enabledUids: tokens.map(\.tokenQuery.id))
        }
    }
}

extension WatchModule {
    enum Items {
        case coins(tokens: [Token])
        case blockchains(blockchains: [Blockchain])
    }
}

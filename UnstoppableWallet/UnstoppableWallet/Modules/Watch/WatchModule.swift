import MarketKit
import SwiftUI
import UIKit

enum WatchModule {
    static func viewController(onWatch: @escaping () -> Void) -> UIViewController {
        let addressParserChain = AddressParserChain()
        addressParserChain.append(handlers:
            AddressParserFactory.parserChainHandlers(blockchainType: .ethereum, withEns: true)
                + BtcBlockchainManager.blockchainTypes.flatMap {
                    AddressParserFactory.parserChainHandlers(blockchainType: $0, withEns: false)
                }
                + AddressParserFactory.parserChainHandlers(blockchainType: .tron)
                + AddressParserFactory.parserChainHandlers(blockchainType: .ton)
                + AddressParserFactory.parserChainHandlers(blockchainType: .stellar)
        )

        let service = WatchService(
            accountFactory: Core.shared.accountFactory,
            addressParserChain: addressParserChain,
            uriParser: AddressParserFactory.parser(blockchainType: nil, tokenType: nil)
        )
        let viewModel = WatchViewModel(service: service)
        let viewController = WatchViewController(viewModel: viewModel, onWatch: onWatch)

        return ThemeNavigationController(rootViewController: viewController)
    }

    static func viewController(onWatch: @escaping () -> Void, accountType: AccountType, name: String) -> UIViewController? {
        let service = ChooseWatchService(
            accountType: accountType,
            accountName: name,
            accountFactory: Core.shared.accountFactory,
            accountManager: Core.shared.accountManager,
            walletManager: Core.shared.walletManager,
            marketKit: Core.shared.marketKit,
            evmBlockchainManager: Core.shared.evmBlockchainManager
        )

        if case let .coins(tokens) = service.items, tokens.count <= 1 {
            return nil
        } else {
            let viewModel = ChooseWatchViewModel(service: service)

            return ChooseWatchViewController(viewModel: viewModel, onWatch: onWatch)
        }
    }

    static func watch(accountType: AccountType, name: String) {
        let service = ChooseWatchService(
            accountType: accountType,
            accountName: name,
            accountFactory: Core.shared.accountFactory,
            accountManager: Core.shared.accountManager,
            walletManager: Core.shared.walletManager,
            marketKit: Core.shared.marketKit,
            evmBlockchainManager: Core.shared.evmBlockchainManager
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

struct WatchView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let onWatch: () -> Void

    func makeUIViewController(context _: Context) -> UIViewController {
        WatchModule.viewController(onWatch: onWatch)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}

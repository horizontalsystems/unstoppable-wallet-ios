import EvmKit
import Foundation
import MarketKit
import UIKit

enum AddTokenModule {
    static func viewController() -> UIViewController? {
        guard let account = Core.shared.accountManager.activeAccount else {
            return nil
        }

        var items = [Item]()

        for blockchain in Core.shared.evmBlockchainManager.allBlockchains {
            if let service: IAddTokenBlockchainService = AddEvmTokenBlockchainService(
                blockchain: blockchain,
                networkManager: Core.shared.networkManager,
                evmSyncSourceManager: Core.shared.evmSyncSourceManager
            ) {
                let item = Item(blockchain: blockchain, service: service)
                items.append(item)
            }
        }

        if let blockchain = try? Core.shared.marketKit.blockchain(uid: BlockchainType.tron.uid), blockchain.type.supports(accountType: account.type) {
            let service: IAddTokenBlockchainService = AddTronTokenBlockchainService(
                blockchain: blockchain,
                networkManager: Core.shared.networkManager,
                network: Core.shared.testNetManager.testNetEnabled ? .nileTestnet : .mainNet
            )

            let item = Item(blockchain: blockchain, service: service)
            items.append(item)
        }

        if let blockchain = try? Core.shared.marketKit.blockchain(uid: BlockchainType.ton.uid), blockchain.type.supports(accountType: account.type) {
            let service: IAddTokenBlockchainService = AddJettonBlockchainService(blockchain: blockchain)
            let item = Item(blockchain: blockchain, service: service)
            items.append(item)
        }

        let service = AddTokenService(account: account, items: items, coinManager: Core.shared.coinManager, walletManager: Core.shared.walletManager)
        let viewModel = AddTokenViewModel(service: service)
        let viewController = AddTokenViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }
}

extension AddTokenModule {
    struct Item {
        let blockchain: Blockchain
        let service: IAddTokenBlockchainService
    }
}

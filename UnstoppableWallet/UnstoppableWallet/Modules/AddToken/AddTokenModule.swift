import Foundation
import UIKit
import ThemeKit
import EvmKit
import MarketKit

struct AddTokenModule {

    static func viewController() -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        var items = [Item]()

        for blockchain in App.shared.evmBlockchainManager.allBlockchains {
            if let service: IAddTokenBlockchainService = AddEvmTokenBlockchainService(
                    blockchain: blockchain,
                    networkManager: App.shared.networkManager,
                    evmSyncSourceManager: App.shared.evmSyncSourceManager
            ) {
                let item = Item(blockchain: blockchain, service: service)
                items.append(item)
            }

        }

        if let blockchain = try? App.shared.marketKit.blockchain(uid: BlockchainType.binanceChain.uid), blockchain.type.supports(accountType: account.type) {
            let service: IAddTokenBlockchainService = AddBep2TokenBlockchainService(
                    blockchain: blockchain,
                    networkManager: App.shared.networkManager
            )
            let item = Item(blockchain: blockchain, service: service)
            items.append(item)
        }

        if let blockchain = try? App.shared.marketKit.blockchain(uid: BlockchainType.tron.uid), blockchain.type.supports(accountType: account.type) {
            let service: IAddTokenBlockchainService = AddTronTokenBlockchainService(
                blockchain: blockchain,
                networkManager: App.shared.networkManager,
                network: App.shared.testNetManager.testNetEnabled ? .nileTestnet : .mainNet
            )

            let item = Item(blockchain: blockchain, service: service)
            items.append(item)
        }

        let service = AddTokenService(account: account, items: items, coinManager: App.shared.coinManager, walletManager: App.shared.walletManager)
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

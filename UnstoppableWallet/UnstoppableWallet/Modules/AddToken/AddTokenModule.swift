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

        var addTokenServices: [IAddTokenBlockchainService] = App.shared.evmBlockchainManager.allBlockchains.compactMap {
            AddEvmTokenBlockchainService(blockchain: $0, networkManager: App.shared.networkManager, evmSyncSourceManager: App.shared.evmSyncSourceManager)
        }

        if let service = AddBep2TokenBlockchainService(marketKit: App.shared.marketKit, networkManager: App.shared.networkManager) {
            addTokenServices.append(service)
        }

        let service = AddTokenService(account: account, blockchainServices: addTokenServices, marketKit: App.shared.marketKit, coinManager: App.shared.coinManager, walletManager: App.shared.walletManager)
        let viewModel = AddTokenViewModel(service: service)
        let viewController = AddTokenViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}

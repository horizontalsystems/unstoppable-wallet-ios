import Foundation
import MarketKit

import UIKit

enum AddMoneroNodeModule {
    static func viewController(blockchainType: BlockchainType) -> UIViewController {
        let service = AddMoneroNodeService(blockchainType: blockchainType, moneroNodeManager: Core.shared.moneroNodeManager)
        let viewModel = AddMoneroNodeViewModel(service: service)
        let viewController = AddMoneroNodeViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }
}

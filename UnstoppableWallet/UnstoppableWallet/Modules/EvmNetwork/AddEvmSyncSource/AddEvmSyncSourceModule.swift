import Foundation
import MarketKit
import ThemeKit
import UIKit

struct AddEvmSyncSourceModule {
    static func viewController(blockchainType: BlockchainType) -> UIViewController {
        let service = AddEvmSyncSourceService(blockchainType: blockchainType, evmSyncSourceManager: App.shared.evmSyncSourceManager)
        let viewModel = AddEvmSyncSourceViewModel(service: service)
        let viewController = AddEvmSyncSourceViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }
}

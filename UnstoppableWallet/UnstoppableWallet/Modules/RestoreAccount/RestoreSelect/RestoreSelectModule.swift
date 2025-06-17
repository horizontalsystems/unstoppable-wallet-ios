import HdWalletKit
import MarketKit
import RxSwift
import UIKit

enum RestoreSelectModule {
    static func viewController(accountName: String, accountType: AccountType, statPage: StatPage, isManualBackedUp: Bool = true, isFileBackedUp: Bool = false, returnViewController: UIViewController?) -> UIViewController {
        let (blockchainTokensService, blockchainTokensView) = BlockchainTokensModule.module()
        let (restoreSettingsService, restoreSettingsView) = RestoreSettingsModule.module(statPage: .restoreSelect)

        let service = RestoreSelectService(
            accountName: accountName,
            accountType: accountType,
            statPage: statPage,
            isManualBackedUp: isManualBackedUp,
            isFileBackedUp: isFileBackedUp,
            accountFactory: Core.shared.accountFactory,
            accountManager: Core.shared.accountManager,
            walletManager: Core.shared.walletManager,
            restoreStateManager: Core.shared.restoreStateManager,
            marketKit: Core.shared.marketKit,
            blockchainTokensService: blockchainTokensService,
            restoreSettingsService: restoreSettingsService
        )

        let viewModel = RestoreSelectViewModel(service: service)

        return RestoreSelectViewController(
            viewModel: viewModel,
            blockchainTokensView: blockchainTokensView,
            restoreSettingsView: restoreSettingsView,
            returnViewController: returnViewController
        )
    }
}

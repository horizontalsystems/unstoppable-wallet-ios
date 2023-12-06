import ThemeKit
import UIKit

enum CexCoinSelectModule {
    static func viewController(mode: Mode) -> UIViewController? {
        guard let service = CexCoinSelectService(accountManager: App.shared.accountManager, mode: mode, cexAssetManager: App.shared.cexAssetManager) else {
            return nil
        }

        let viewModel = CexCoinSelectViewModel(service: service)
        let viewController = CexCoinSelectViewController(viewModel: viewModel, mode: mode)

        return ThemeNavigationController(rootViewController: viewController)
    }
}

extension CexCoinSelectModule {
    enum Mode {
        case deposit
        case withdraw
    }
}

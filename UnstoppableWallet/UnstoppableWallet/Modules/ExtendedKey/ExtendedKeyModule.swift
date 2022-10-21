import UIKit
import ThemeKit

struct ExtendedKeyModule {

    static func viewController(mode: Mode, accountType: AccountType) -> UIViewController {
        let service = ExtendedKeyService(mode: mode, accountType: accountType)
        let viewModel = ExtendedKeyViewModel(service: service)
        let viewController = ExtendedKeyViewController(viewModel: viewModel)
        return ThemeNavigationController(rootViewController: viewController)
    }

}

extension ExtendedKeyModule {

    enum Mode {
        case bip32RootKey
        case accountExtendedPrivateKey
        case accountExtendedPublicKey
    }

}

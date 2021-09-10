import UIKit
import ThemeKit

struct CreateAccountModule {

    static func viewController() -> UIViewController {
        let service = CreateAccountService(
                accountFactory: App.shared.accountFactory,
                wordsManager: App.shared.wordsManager,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManagerNew,
                passphraseValidator: PassphraseValidator(),
                marketKit: App.shared.marketKit
        )
        let viewModel = CreateAccountViewModel(service: service)
        let viewController = CreateAccountViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}

extension CreateAccountModule {

    enum Kind: CaseIterable {
        case mnemonic12
        case mnemonic24

        var title: String {
            switch self {
            case .mnemonic12: return "create_wallet.n_words".localized("12")
            case .mnemonic24: return "create_wallet.n_words".localized("24")
            }
        }
    }

}

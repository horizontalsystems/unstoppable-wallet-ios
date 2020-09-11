import UIKit
import ThemeKit

struct CreateWalletModule {

    static func instance(presentationMode: CreateWalletModule.PresentationMode, predefinedAccountType: PredefinedAccountType? = nil) -> UIViewController {
        let service = CreateWalletService(
                predefinedAccountType: predefinedAccountType,
                coinManager: App.shared.coinManager,
                accountCreator: App.shared.accountCreator,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager,
                derivationSettingsManager: App.shared.derivationSettingsManager
        )
        let viewModel = CreateWalletViewModel(service: service)
        let viewController = CreateWalletViewController(viewModel: viewModel, presentationMode: presentationMode)

        switch presentationMode {
        case .initial: return viewController
        case .inApp: return ThemeNavigationController(rootViewController: viewController)
        }
    }

    enum PresentationMode {
        case initial
        case inApp
    }

}

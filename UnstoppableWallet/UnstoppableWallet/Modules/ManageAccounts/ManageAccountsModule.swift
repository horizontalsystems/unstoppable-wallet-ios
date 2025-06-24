import SwiftUI
import UIKit

enum ManageAccountsModule {
    static func viewController(mode: Mode, createAccountListener: ICreateAccountListener? = nil) -> UIViewController {
        let service = ManageAccountsService(accountManager: Core.shared.accountManager, cloudBackupManager: Core.shared.cloudBackupManager)
        let viewModel = ManageAccountsViewModel(service: service, mode: mode)
        return ManageAccountsViewController(viewModel: viewModel, createAccountListener: createAccountListener)
    }
}

extension ManageAccountsModule {
    enum Mode {
        case manage
        case switcher
    }
}

struct ManageAccountsView2: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    private let mode: ManageAccountsModule.Mode
    private let createAccountListener: ICreateAccountListener?

    init(mode: ManageAccountsModule.Mode, createAccountListener: ICreateAccountListener? = nil) {
        self.mode = mode
        self.createAccountListener = createAccountListener
    }

    func makeUIViewController(context _: Context) -> UIViewController {
        ManageAccountsModule.viewController(mode: mode, createAccountListener: createAccountListener)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}

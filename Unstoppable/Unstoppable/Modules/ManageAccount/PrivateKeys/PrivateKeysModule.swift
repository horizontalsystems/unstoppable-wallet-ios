import SwiftUI
import UIKit

enum PrivateKeysModule {
    static func viewController(account: Account) -> UIViewController {
        let service = PrivateKeysService(account: account, passcodeManager: Core.shared.passcodeManager)
        let viewModel = PrivateKeysViewModel(service: service)
        return PrivateKeysViewController(viewModel: viewModel)
    }
}

struct PrivateKeysView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    private let account: Account

    init(account: Account) {
        self.account = account
    }

    func makeUIViewController(context _: Context) -> UIViewController {
        PrivateKeysModule.viewController(account: account)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}

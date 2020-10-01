import UIKit

struct WalletConnectModule {

    static func start(sourceViewController: UIViewController?) {
        let service = WalletConnectService(ethereumKitManager: App.shared.ethereumKitManager)
        let viewModel = WalletConnectViewModel(service: service)
        let view = WalletConnectView(viewModel: viewModel)

        view.start(sourceViewController: sourceViewController)
    }

}

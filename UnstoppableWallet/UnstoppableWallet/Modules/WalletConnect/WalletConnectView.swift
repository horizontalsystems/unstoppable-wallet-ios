import ThemeKit

class WalletConnectView {
    let viewModel: WalletConnectViewModel

    init(viewModel: WalletConnectViewModel) {
        self.viewModel = viewModel
    }

    private func initialViewController(initialScreen: WalletConnectViewModel.InitialScreen, sourceViewController: UIViewController?) -> UIViewController {
        switch initialScreen {
        case .scanQrCode:
            return WalletConnectScanQrViewController(baseViewModel: viewModel, sourceViewController: sourceViewController)
        case .main:
            let viewController = WalletConnectMainViewController(baseViewModel: viewModel, sourceViewController: sourceViewController)
            return ThemeNavigationController(rootViewController: viewController)
        }
    }

}

extension WalletConnectView {

    func start(sourceViewController: UIViewController?) {
        let viewController = initialViewController(initialScreen: viewModel.initialScreen, sourceViewController: sourceViewController)
        sourceViewController?.present(viewController, animated: true)
    }

}

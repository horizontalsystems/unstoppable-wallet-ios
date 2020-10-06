import ThemeKit

class WalletConnectView {
    private let viewModel: WalletConnectViewModel
    private weak var sourceViewController: UIViewController?

    init(viewModel: WalletConnectViewModel, sourceViewController: UIViewController?) {
        self.viewModel = viewModel
        self.sourceViewController = sourceViewController
    }

    var initialViewController: UIViewController {
        switch viewModel.initialScreen {
        case .noEthereumKit:
            return WalletConnectNoEthereumKitViewController().toBottomSheet
        case .scanQrCode:
            return WalletConnectScanQrViewController(viewModel: viewModel, sourceViewController: sourceViewController)
        case .main:
            return ThemeNavigationController(rootViewController: WalletConnectMainViewController(viewModel: viewModel, sourceViewController: sourceViewController))
        }
    }

}

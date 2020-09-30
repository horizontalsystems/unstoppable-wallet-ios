import ThemeKit

class WalletConnectScanQrViewController: ScanQrViewController {
    weak var sourceViewController: UIViewController?

    private let baseViewModel: WalletConnectViewModel
    private let viewModel: WalletConnectScanQrViewModel

    init(baseViewModel: WalletConnectViewModel, sourceViewController: UIViewController?) {
        self.baseViewModel = baseViewModel
        self.sourceViewController = sourceViewController

        viewModel = baseViewModel.scanQrViewModel

        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func onScan(string: String) {
        viewModel.didScan(string: string)

        let viewController = WalletConnectInitialConnectViewController(baseViewModel: baseViewModel, sourceViewController: sourceViewController)
        present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

}

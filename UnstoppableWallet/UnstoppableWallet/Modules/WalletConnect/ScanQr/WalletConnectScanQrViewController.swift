import ThemeKit
import RxSwift
import RxCocoa

class WalletConnectScanQrViewController: ScanQrViewController {
    private let baseViewModel: WalletConnectViewModel
    private let viewModel: WalletConnectScanQrViewModel
    private weak var sourceViewController: UIViewController?

    private let disposeBag = DisposeBag()

    init(baseViewModel: WalletConnectViewModel, sourceViewController: UIViewController?) {
        self.baseViewModel = baseViewModel
        viewModel = baseViewModel.scanQrViewModel
        self.sourceViewController = sourceViewController

        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.openMainSignal
                .emit(onNext: { [weak self] in
                    self?.openMain()
                })
                .disposed(by: disposeBag)

        viewModel.openErrorSignal
                .emit(onNext: { [weak self] error in
                    self?.openError(error: error)
                })
                .disposed(by: disposeBag)
    }

    override func onScan(string: String) {
        viewModel.handleScanned(string: string)
    }

    private func openMain() {
        let viewController = WalletConnectMainViewController(baseViewModel: baseViewModel, sourceViewController: sourceViewController)
        dismiss(animated: true) { [weak self] in
            self?.sourceViewController?.present(ThemeNavigationController(rootViewController: viewController), animated: true)
        }
    }

    private func openError(error: Error) {
        let viewController = WalletConnectErrorViewController(error: error, sourceViewController: sourceViewController)
        present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

}

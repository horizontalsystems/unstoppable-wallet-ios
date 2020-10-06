import ThemeKit
import RxSwift
import RxCocoa

class WalletConnectScanQrViewController: ScanQrViewController {
    private let viewModel: WalletConnectViewModel
    private let presenter: WalletConnectScanQrPresenter
    private weak var sourceViewController: UIViewController?

    private let disposeBag = DisposeBag()

    init(viewModel: WalletConnectViewModel, sourceViewController: UIViewController?) {
        self.viewModel = viewModel
        presenter = viewModel.scanQrPresenter
        self.sourceViewController = sourceViewController

        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        presenter.openMainSignal
                .emit(onNext: { [weak self] in
                    self?.openMain()
                })
                .disposed(by: disposeBag)

        presenter.openErrorSignal
                .emit(onNext: { [weak self] error in
                    self?.openError(error: error)
                })
                .disposed(by: disposeBag)
    }

    override func onScan(string: String) {
        presenter.handleScanned(string: string)
    }

    private func openMain() {
        let viewController = WalletConnectMainViewController(viewModel: viewModel, sourceViewController: sourceViewController)
        present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

    private func openError(error: Error) {
        let viewController = WalletConnectErrorViewController(error: error, sourceViewController: sourceViewController)
        present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

}

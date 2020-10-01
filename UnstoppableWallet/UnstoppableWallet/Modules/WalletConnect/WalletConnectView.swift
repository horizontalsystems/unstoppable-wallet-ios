import ThemeKit
import RxSwift
import RxRelay
import RxCocoa

class WalletConnectView {
    let viewModel: WalletConnectViewModel

    private let disposeBag = DisposeBag()

    private weak var sourceViewController: UIViewController?
    private weak var currentViewController: UIViewController?

    init(viewModel: WalletConnectViewModel) {
        self.viewModel = viewModel

        viewModel.openScreenSignal
                .emit(onNext: { [weak self] screen in
                    self?.open(screen: screen)
                })
                .disposed(by: disposeBag)

        viewModel.finishSignal
                .emit(onNext: { [weak self] in
                    self?.finish()
                })
                .disposed(by: disposeBag)
    }

    private func open(screen: WalletConnectViewModel.Screen) {
        guard let viewController = viewController(screen: screen) else {
            return
        }

        currentViewController?.present(viewController, animated: true)
        currentViewController = viewController
    }

    private func finish() {
        sourceViewController?.dismiss(animated: true)
    }

    private func viewController(screen: WalletConnectViewModel.Screen) -> UIViewController? {
        switch screen {
        case .noEthereumKit:
            return WalletConnectNoEthereumKitViewController().toBottomSheet
        case .scanQrCode:
            return WalletConnectScanQrViewController(baseView: self)
        case .error(let error):
            return navigationController(viewController: WalletConnectErrorViewController(baseView: self, error: error))
        case .initialConnect:
            return navigationController(viewController: WalletConnectInitialConnectModule.viewController(baseView: self))
        case .main:
            return navigationController(viewController: WalletConnectMainModule.viewController(baseView: self))
        }
    }

    private func navigationController(viewController: UIViewController?) -> UINavigationController? {
        guard let viewController = viewController else {
            return nil
        }

        return ThemeNavigationController(rootViewController: viewController)
    }

}

extension WalletConnectView {

    func start(sourceViewController: UIViewController?) {
        self.sourceViewController = sourceViewController

        guard let viewController = viewController(screen: viewModel.initialScreen) else {
            return
        }

        currentViewController = viewController
        sourceViewController?.present(viewController, animated: true)
    }

}

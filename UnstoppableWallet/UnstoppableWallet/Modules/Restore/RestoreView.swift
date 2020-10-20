import ThemeKit
import RxSwift
import RxRelay
import RxCocoa

class RestoreView {
    weak var navigationController: UINavigationController?
    let viewModel: RestoreViewModel
    private var onComplete: (() -> ())?

    private let disposeBag = DisposeBag()

    init(viewModel: RestoreViewModel, onComplete: (() -> ())? = nil) {
        self.viewModel = viewModel
        self.onComplete = onComplete

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

    private func open(screen: RestoreViewModel.Screen) {
        navigationController?.pushViewController(viewController(screen: screen), animated: true)
    }

    private func finish() {
        if let onComplete = onComplete {
            onComplete()
        } else {
            navigationController?.dismiss(animated: true)
        }
    }

    private func viewController(screen: RestoreViewModel.Screen) -> UIViewController {
        switch screen {

        case .selectPredefinedAccountType:
            return RestoreSelectPredefinedAccountTypeModule.viewController(restoreView: self)

        case .restoreAccountType(let predefinedAccountType):
            switch predefinedAccountType {
            case .standard:
                return RestoreWordsModule.viewController(restoreView: self, wordCount: 12)
            case .eos:
                return RestoreEosModule.viewController(restoreView: self)
            case .binance, .zCash:
                return RestoreWordsModule.viewController(restoreView: self, wordCount: 24)
            }

        case .selectCoins(let predefinedAccountType):
            return RestoreSelectCoinsModule.viewController(predefinedAccountType: predefinedAccountType, restoreView: self)

        }
    }

}

extension RestoreView {

    func start(mode: ModuleStartMode) {
        let initialViewController = viewController(screen: viewModel.initialScreen)

        switch mode {
        case .push(let navigationController):
            self.navigationController = navigationController

            navigationController?.pushViewController(initialViewController, animated: true)
        case .present(let viewController):
            let navigationController = ThemeNavigationController(rootViewController: initialViewController)
            self.navigationController = navigationController

            viewController?.present(navigationController, animated: true)
        }
    }

}

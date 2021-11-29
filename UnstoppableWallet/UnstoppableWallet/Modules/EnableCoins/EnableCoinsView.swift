import ThemeKit
import RxSwift
import RxRelay
import RxCocoa
import ComponentKit

class EnableCoinsView {
    private let viewModel: EnableCoinsViewModel
    private let disposeBag = DisposeBag()

    var onOpenController: ((UIViewController) -> ())?

    init(viewModel: EnableCoinsViewModel) {
        self.viewModel = viewModel

        subscribe(disposeBag, viewModel.hudStateDriver) { [weak self] hudState in
            self?.handle(hudState: hudState)
        }
        subscribe(disposeBag, viewModel.confirmationSignal) { [weak self] tokenType in
            self?.handleConfirmation(tokenType: tokenType)
        }
    }

    private func handle(hudState: EnableCoinsViewModel.HudState) {
        switch hudState {
        case .hidden:
            HudHelper.instance.hide()
        case .loading:
            HudHelper.instance.showSpinner(title: "enable_coins.enabling".localized)
        case .success:
            HudHelper.instance.hide()
        case .error:
            HudHelper.instance.showError()
        }
    }

    private func handleConfirmation(tokenType: String) {
        let controller = EnableCoinsConfirmationViewController(tokenType: tokenType) { [weak self] in
            self?.viewModel.onConfirmEnable()
        }

        onOpenController?(controller.toBottomSheet)
    }

}

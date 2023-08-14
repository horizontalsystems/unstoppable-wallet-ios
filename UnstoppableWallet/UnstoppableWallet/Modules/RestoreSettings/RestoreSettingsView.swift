import UIKit
import RxSwift
import RxCocoa
import MarketKit
import ThemeKit

class RestoreSettingsView {
    private let viewModel: RestoreSettingsViewModel
    private let disposeBag = DisposeBag()

    var onOpenController: ((UIViewController) -> ())?

    init(viewModel: RestoreSettingsViewModel) {
        self.viewModel = viewModel

        subscribe(disposeBag, viewModel.openBirthdayAlertSignal) { [weak self] token in
            self?.showBirthdayAlert(token: token)
        }
    }

    private func showBirthdayAlert(token: Token) {
        let controller = BirthdayInputViewController(token: token)
        controller.onEnterBirthdayHeight = { [weak self] height in
            self?.viewModel.onEnter(birthdayHeight: height)
        }
        controller.onCancel = { [weak self] in
            self?.viewModel.onCancelEnterBirthdayHeight()
        }
        onOpenController?(ThemeNavigationController(rootViewController: controller))
    }

}

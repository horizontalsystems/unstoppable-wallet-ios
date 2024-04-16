import MarketKit
import RxCocoa
import RxSwift
import ThemeKit
import UIKit

class RestoreSettingsView {
    private let viewModel: RestoreSettingsViewModel
    private let statPage: StatPage
    private let disposeBag = DisposeBag()

    var onOpenController: ((UIViewController) -> Void)?

    init(viewModel: RestoreSettingsViewModel, statPage: StatPage) {
        self.viewModel = viewModel
        self.statPage = statPage

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

        stat(page: statPage, event: .open(page: .birthdayInput))
    }
}

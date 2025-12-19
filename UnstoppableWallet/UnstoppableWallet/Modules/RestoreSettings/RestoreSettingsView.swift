import MarketKit
import Combine
import UIKit

class RestoreSettingsView {
    private let viewModel: RestoreSettingsViewModel
    private let statPage: StatPage
    private var cancellables: [AnyCancellable] = []

    var onOpenController: ((UIViewController) -> Void)?

    init(viewModel: RestoreSettingsViewModel, statPage: StatPage) {
        self.viewModel = viewModel
        self.statPage = statPage

        viewModel.openBirthdayAlertPublisher.sink { [weak self] token in
            self?.showBirthdayAlert(token: token)
        }.store(in: &cancellables)
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

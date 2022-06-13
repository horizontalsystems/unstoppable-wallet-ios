import UIKit
import RxSwift
import RxCocoa
import MarketKit

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
        let controller = BirthdayInputViewController(token: token, delegate: self).toAlert
        onOpenController?(controller)
    }

}

extension RestoreSettingsView: IBirthdayInputDelegate {

    func didEnter(birthdayHeight: Int?) {
        viewModel.onEnter(birthdayHeight: birthdayHeight)
    }

    func didCancelEnterBirthdayHeight() {
        viewModel.onCancelEnterBirthdayHeight()
    }

}

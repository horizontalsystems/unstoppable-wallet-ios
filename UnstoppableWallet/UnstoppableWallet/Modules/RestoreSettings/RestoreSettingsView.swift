import UIKit
import RxSwift
import RxCocoa
import CoinKit

class RestoreSettingsView {
    private let viewModel: RestoreSettingsViewModel
    private let disposeBag = DisposeBag()

    var onOpenController: ((UIViewController) -> ())?

    init(viewModel: RestoreSettingsViewModel) {
        self.viewModel = viewModel

        subscribe(disposeBag, viewModel.openBirthdayAlertSignal) { [weak self] coin in
            self?.showBirthdayAlert(coin: coin)
        }
    }

    private func showBirthdayAlert(coin: Coin) {
        let controller = BirthdayInputViewController(coin: coin, delegate: self).toAlert
        onOpenController?(controller)
    }

}

extension RestoreSettingsView: IBirthdayInputDelegate {

    func didEnter(birthdayHeight: Int) {
        viewModel.onEnter(birthdayHeight: birthdayHeight)
    }

    func didCancelEnterBirthdayHeight() {
        viewModel.onCancelEnterBirthdayHeight()
    }

}

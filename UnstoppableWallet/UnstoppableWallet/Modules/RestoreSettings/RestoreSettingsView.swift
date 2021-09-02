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

        subscribe(disposeBag, viewModel.openBirthdayAlertSignal) { [weak self] platformCoin in
            self?.showBirthdayAlert(platformCoin: platformCoin)
        }
    }

    private func showBirthdayAlert(platformCoin: PlatformCoin) {
        let controller = BirthdayInputViewController(platformCoin: platformCoin, delegate: self).toAlert
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

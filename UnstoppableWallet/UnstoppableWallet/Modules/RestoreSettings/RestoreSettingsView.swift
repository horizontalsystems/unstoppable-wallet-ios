import UIKit
import RxSwift
import RxCocoa

class RestoreSettingsView {
    private let viewModel: RestoreSettingsViewModel
    private let disposeBag = DisposeBag()

    var onOpenController: ((UIViewController) -> ())?

    init(viewModel: RestoreSettingsViewModel) {
        self.viewModel = viewModel

        subscribe(disposeBag, viewModel.openBirthdayAlertSignal) { [weak self] coinTitle in
            self?.showBirthdayAlert(coinTitle: coinTitle)
        }
    }

    private func showBirthdayAlert(coinTitle: String) {
        let controller = UIAlertController(title: "\(coinTitle) Birthday Height", message: "Enter birthday height if you know", preferredStyle: .alert)
        controller.addTextField()

        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
            let value = controller.textFields?.first?.text
            self?.viewModel.onEnter(birthdayHeight: value)
        }
        controller.addAction(submitAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.viewModel.onCancelEnterBirthdayHeight()
        }
        controller.addAction(cancelAction)

        onOpenController?(controller)
    }

}

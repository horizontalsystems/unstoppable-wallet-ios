import UIKit
import RxSwift
import RxCocoa

class CoinSettingsView {
    private let viewModel: CoinSettingsViewModel
    private let disposeBag = DisposeBag()

    var onOpenController: ((UIViewController) -> ())?

    init(viewModel: CoinSettingsViewModel) {
        self.viewModel = viewModel

        subscribe(disposeBag, viewModel.openBottomSelectorSignal) { [weak self] config in
            self?.showBottomSelector(config: config)
        }
    }

    private func showBottomSelector(config: BottomMultiSelectorViewController.Config) {
        let controller = BottomMultiSelectorViewController(config: config, delegate: self).toBottomSheet
        onOpenController?(controller)
    }

}

extension CoinSettingsView: IBottomMultiSelectorDelegate {

    func bottomSelectorOnSelect(indexes: [Int]) {
        viewModel.onSelect(indexes: indexes)
    }

    func bottomSelectorOnCancel() {
        viewModel.onCancelSelect()
    }

}

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

    private func showBottomSelector(config: SelectorModule.MultiConfig) {
        let controller = SelectorModule.bottomMultiSelectorViewController(config: config, delegate: self)
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

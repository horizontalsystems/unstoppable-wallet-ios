import UIKit
import RxSwift
import RxCocoa

class CoinTokensView {
    private let viewModel: CoinTokensViewModel
    private let disposeBag = DisposeBag()

    var onOpenController: ((UIViewController) -> ())?

    init(viewModel: CoinTokensViewModel) {
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

extension CoinTokensView: IBottomMultiSelectorDelegate {

    func bottomSelectorOnSelect(indexes: [Int]) {
        viewModel.onSelect(indexes: indexes)
    }

    func bottomSelectorOnCancel() {
        viewModel.onCancelSelect()
    }

}

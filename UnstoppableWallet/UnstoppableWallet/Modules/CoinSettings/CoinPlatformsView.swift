import UIKit
import RxSwift
import RxCocoa

class CoinPlatformsView {
    private let viewModel: CoinPlatformsViewModel
    private let disposeBag = DisposeBag()

    var onOpenController: ((UIViewController) -> ())?

    init(viewModel: CoinPlatformsViewModel) {
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

extension CoinPlatformsView: IBottomMultiSelectorDelegate {

    func bottomSelectorOnSelect(indexes: [Int]) {
        viewModel.onSelect(indexes: indexes)
    }

    func bottomSelectorOnCancel() {
        viewModel.onCancelSelect()
    }

}

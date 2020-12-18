import UIKit
import RxSwift
import RxCocoa

class BlockchainSettingsView {
    private let viewModel: BlockchainSettingsViewModel
    private let disposeBag = DisposeBag()

    var onOpenController: ((UIViewController) -> ())?

    init(viewModel: BlockchainSettingsViewModel) {
        self.viewModel = viewModel

        subscribe(disposeBag, viewModel.openBottomSelectorSignal) { [weak self] config in
            self?.showBottomSelector(config: config)
        }
    }

    private func showBottomSelector(config: BottomSelectorViewController.Config) {
        let controller = BottomSelectorViewController(config: config, delegate: self).toBottomSheet
        onOpenController?(controller)
    }

}

extension BlockchainSettingsView: IBottomSelectorDelegate {

    func bottomSelectorOnSelect(index: Int) {
        viewModel.onSelect(index: index)
    }

    func bottomSelectorOnCancel() {
        viewModel.onCancelSelect()
    }

}

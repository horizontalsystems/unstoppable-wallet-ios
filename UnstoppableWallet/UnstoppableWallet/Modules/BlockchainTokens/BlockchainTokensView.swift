import UIKit
import Combine

class BlockchainTokensView {
    private let viewModel: BlockchainTokensViewModel
    private var cancellables: [AnyCancellable] = []

    var onOpenController: ((UIViewController) -> Void)?

    init(viewModel: BlockchainTokensViewModel) {
        self.viewModel = viewModel

        viewModel.openBottomSelectorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] config in
                self?.showBottomSelector(config: config)
            }
            .store(in: &cancellables)
    }

    private func showBottomSelector(config: SelectorModule.MultiConfig) {
        let controller = SelectorModule.bottomMultiSelectorViewController(config: config, delegate: self)
        onOpenController?(controller)
    }
}

extension BlockchainTokensView: IBottomMultiSelectorDelegate {
    func bottomSelectorOnSelect(indexes: [Int]) {
        viewModel.onSelect(indexes: indexes)
    }

    func bottomSelectorOnCancel() {
        viewModel.onCancelSelect()
    }
}

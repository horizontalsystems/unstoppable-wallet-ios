import UIKit
import RxSwift

class MarketTabsView: UITableViewHeaderFooterView {
    private let disposeBag = DisposeBag()
    private let viewModel: MarketTabsViewModel

    private let tabsView = FilterHeaderView()

    init(viewModel: MarketTabsViewModel) {
        self.viewModel = viewModel

        super.init(reuseIdentifier: nil)

        contentView.addSubview(tabsView)
        tabsView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tabsView.onSelect = { [weak self] index in
            self?.onSelect(index: index)
        }

        tabsView.reload(filters: viewModel.tabs)

        syncIndex()
        subscribe(disposeBag, viewModel.updateIndexSignal) { [weak self] in self?.syncIndex() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func syncIndex() {
        tabsView.select(index: viewModel.currentIndex)
    }

    private func onSelect(index: Int) {
         viewModel.didSelect(index: index)
    }

}

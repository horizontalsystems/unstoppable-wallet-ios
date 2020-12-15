import UIKit
import RxSwift

class MarketCategoriesView: UITableViewHeaderFooterView {
    private let disposeBag = DisposeBag()
    private let viewModel: MarketCategoriesViewModel

    private let categoriesView = FilterHeaderView()

    init(viewModel: MarketCategoriesViewModel) {
        self.viewModel = viewModel

        super.init(reuseIdentifier: nil)

        contentView.addSubview(categoriesView)
        categoriesView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        categoriesView.onSelect = { [weak self] index in
            self?.onSelect(index: index)
        }

        categoriesView.reload(filters: viewModel.categories)

        syncIndex()
        subscribe(disposeBag, viewModel.updateIndexSignal) { [weak self] in self?.syncIndex() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func syncIndex() {
        categoriesView.select(index: viewModel.currentIndex)
    }

    private func onSelect(index: Int) {
         viewModel.didSelect(index: index)
    }

}

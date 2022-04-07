import RxSwift
import RxCocoa
import SectionsTableView

class MarketOverviewCategoryDataSource {
    private let disposeBag = DisposeBag()

    weak var parentNavigationController: UINavigationController?

    var status: DataStatus<[SectionProtocol]> = .loading {
        didSet { statusRelay.accept(()) }
    }
    private let statusRelay = PublishRelay<()>()

    private let viewModel: MarketOverviewCategoryViewModel

    private var viewItem: MarketOverviewCategoryViewModel.CategoryViewItem?

    private let categoryCell = MarketOverviewCategoryCell()

    init(viewModel: MarketOverviewCategoryViewModel) {
        self.viewModel = viewModel

        subscribe(disposeBag, viewModel.categoryViewItemsDriver) { [weak self] in self?.sync(viewItem: $0) }
        categoryCell.onSelect = { [weak self] index in
            guard let viewItem = self?.viewItem?.viewItems[index], let viewController = MarketCategoryModule.viewController(categoryUid: viewItem.uid) else {
                return
            }
            self?.parentNavigationController?.present(viewController, animated: true)
        }
    }

    private func sync(viewItem: MarketOverviewCategoryViewModel.CategoryViewItem?) {
        self.viewItem = viewItem
        categoryCell.viewItems = viewItem?.viewItems ?? []

        status = .completed(sections)
    }

    private func onSelect(listViewItem: MarketModule.ListViewItem) {
        guard let uid = listViewItem.uid, let module = CoinPageModule.viewController(coinUid: uid) else {
            return
        }

        parentNavigationController?.present(module, animated: true)
    }

    private var sections: [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let viewItem = viewItem {
            let headerSection = Section(
                    id: "categories_header",
                    rows: [
                        Row<MarketOverviewHeaderCell>(
                                id: "categories_header_cell",
                                height: .heightCell48,
                                bind: { [weak self] cell, _ in
                                    cell.set(backgroundStyle: .transparent)

                                    cell.buttonMode = .seeAll
                                    cell.onSeeAll = {
                                        self?.parentNavigationController?.pushViewController(MarketDiscoveryModule.viewController(), animated: true)
                                    }

                                    cell.titleImage = UIImage(named: viewItem.imageName)
                                    cell.title = viewItem.title
                                }
                        )
                    ]
            )

            let categorySection = Section(
                    id: "categories",
                    rows: [
                        StaticRow(
                                cell: categoryCell,
                                id: "metrics",
                                height: MarketOverviewCategoryCell.cellHeight
                        )
                    ]
            )

            sections.append(headerSection)
            sections.append(categorySection)
        }

        return sections
    }

}

extension MarketOverviewCategoryDataSource: IMarketOverviewDataSource {
    var updateDriver: Driver<()> {
        statusRelay.asDriver(onErrorJustReturn: ())
    }

    func refresh() {
        //categories has no refresh
    }

}

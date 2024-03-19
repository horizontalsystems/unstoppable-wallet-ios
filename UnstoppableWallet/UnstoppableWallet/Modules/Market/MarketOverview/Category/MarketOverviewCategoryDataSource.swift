import RxCocoa
import RxSwift
import SectionsTableView
import UIKit

class MarketOverviewCategoryDataSource {
    private let viewModel: MarketOverviewCategoryViewModel
    weak var presentDelegate: IPresentDelegate?
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[MarketOverviewCategoryViewModel.ViewItem]?>(value: nil)

    private let categoryCell = MarketOverviewCategoryCell()

    init(viewModel: MarketOverviewCategoryViewModel, presentDelegate: IPresentDelegate) {
        self.viewModel = viewModel
        self.presentDelegate = presentDelegate

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] viewItems in
            self?.viewItemsRelay.accept(viewItems)

            if let viewItems {
                self?.categoryCell.viewItems = viewItems
            }
        }

        categoryCell.onSelect = { [weak self] uid in
            guard let category = viewModel.category(uid: uid) else {
                return
            }

            let viewController = MarketCategoryModule.viewController(category: category, apiTag: "market_overview")
            self?.presentDelegate?.present(viewController: viewController)
        }
    }

    func didTapSeeAll() {
        let module = MarketTopModule.viewController(
            marketTop: viewModel.marketTop,
            sortingField: viewModel.listType.sortingField,
            marketField: viewModel.listType.marketField
        )
        presentDelegate?.present(viewController: module)
    }

    private func bind(cell: MarketOverviewHeaderCell) {
        cell.set(backgroundStyle: .transparent)
        cell.buttonMode = .none
        cell.titleImage = UIImage(named: "categories_20")
        cell.title = "market.top.section.header.sectors".localized

        cell.onTapTitle = { [weak self] in
            self?.didTapSeeAll()
        }
    }
}

extension MarketOverviewCategoryDataSource: IMarketOverviewDataSource {
    var isReady: Bool {
        viewItemsRelay.value != nil
    }

    var updateObservable: Observable<Void> {
        viewItemsRelay.map { _ in () }
    }

    func sections(tableView _: SectionsTableView) -> [SectionProtocol] {
        [
            Section(
                id: "categories_header",
                rows: [
                    Row<MarketOverviewHeaderCell>(
                        id: "categories_header_cell",
                        height: .heightCell48,
                        bind: { [weak self] cell, _ in
                            self?.bind(cell: cell)
                        }
                    ),
                ]
            ),
            Section(
                id: "categories",
                footerState: .margin(height: .margin32),
                rows: [
                    StaticRow(
                        cell: categoryCell,
                        id: "categories",
                        height: MarketOverviewCategoryCell.cellHeight
                    ),
                ]
            ),
        ]
    }
}

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
        }

        categoryCell.onSelect = { [weak self] uid in
            guard let category = viewModel.category(uid: uid) else {
                return
            }

            let viewController = MarketCategoryModule.viewController(category: category, apiTag: "market_overview")
            self?.presentDelegate?.present(viewController: viewController)
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
        guard let viewItems = viewItemsRelay.value else {
            return []
        }

        categoryCell.viewItems = viewItems

        return [
            Section(
                id: "categories_header",
                footerState: .margin(height: .margin8),
                rows: [
                    Row<MarketOverviewHeaderCell>(
                        id: "categories_header_cell",
                        height: .heightCell48,
                        bind: { [weak self] cell, _ in
                            cell.set(backgroundStyle: .transparent)

                            cell.buttonMode = .seeAll
                            let onSeeAll: () -> Void = { [weak self] in
                                self?.presentDelegate?.push(viewController: MarketDiscoveryModule.viewController())
                            }
                            cell.onSeeAll = onSeeAll
                            cell.onTapTitle = onSeeAll

                            cell.titleImage = UIImage(named: "categories_20")
                            cell.title = "market.top.section.header.top_sectors".localized
                        }
                    ),
                ]
            ),
            Section(
                id: "categories",
                rows: [
                    StaticRow(
                        cell: categoryCell,
                        id: "metrics",
                        height: MarketOverviewCategoryCell.cellHeight
                    ),
                ]
            ),
        ]
    }
}

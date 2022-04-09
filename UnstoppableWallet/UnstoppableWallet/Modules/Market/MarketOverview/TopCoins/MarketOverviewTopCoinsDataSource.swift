import UIKit
import RxSwift
import RxCocoa
import SectionsTableView
import Chart
import ComponentKit

class MarketOverviewTopCoinsDataSource {
    private let disposeBag = DisposeBag()

    weak var parentNavigationController: UINavigationController? {
        didSet {
            marketMetricsCell.viewController = parentNavigationController
        }
    }
    var status: DataStatus<[SectionProtocol]> = .loading {
        didSet { statusRelay.accept(()) }
    }
    private let statusRelay = PublishRelay<()>()

    private let viewModel: MarketOverviewTopCoinsViewModel

    private var topViewItems: [MarketOverviewTopCoinsViewModel.TopViewItem]?

    private let marketMetricsCell = MarketOverviewMetricsCell(chartConfiguration: ChartConfiguration.smallChart)

    init(viewModel: MarketOverviewTopCoinsViewModel) {
        self.viewModel = viewModel

        subscribe(disposeBag, viewModel.statusDriver) { [weak self] in self?.sync(status: $0) }
    }

    private func sync(status: DataStatus<MarketOverviewTopCoinsViewModel.ViewItem>) {
        self.status = status.map { [weak self] viewItem in
            self?.topViewItems = viewItem.topViewItems
            self?.marketMetricsCell.set(viewItem: viewItem.globalMarketViewItem)

            return sections
        }
    }

    private func row(listViewItem: MarketModule.ListViewItem, isFirst: Bool) -> RowProtocol {
        Row<G14Cell>(
                id: "\(listViewItem.uid ?? "")-\(listViewItem.name)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst)
                    MarketModule.bind(cell: cell, viewItem: listViewItem)
                },
                action: { [weak self] _ in
                    self?.onSelect(listViewItem: listViewItem)
                })
    }

    private func rows(listViewItems: [MarketModule.ListViewItem]) -> [RowProtocol] {
        listViewItems.enumerated().map { index, listViewItem in
            row(listViewItem: listViewItem, isFirst: index == 0)
        }
    }

    private func seeAllRow(id: String, action: @escaping () -> ()) -> RowProtocol {
        Row<B1Cell>(
                id: id,
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isLast: true)
                    cell.title = "market.top.section.header.see_all".localized
                },
                action: { _ in
                    action()
                }
        )
    }

    private func didTapSeeAll(listType: MarketOverviewTopCoinsService.ListType) {
        let module = MarketTopModule.viewController(
                marketTop: viewModel.marketTop(listType: listType),
                sortingField: listType.sortingField,
                marketField: listType.marketField
        )
        parentNavigationController?.present(module, animated: true)
    }

    private func onSelect(listViewItem: MarketModule.ListViewItem) {
        guard let uid = listViewItem.uid, let module = CoinPageModule.viewController(coinUid: uid) else {
            return
        }

        parentNavigationController?.present(module, animated: true)
    }

    private var sections: [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let viewItems = topViewItems {
            let metricsSection = Section(
                    id: "market_metrics",
                    rows: [
                        StaticRow(
                                cell: marketMetricsCell,
                                id: "metrics",
                                height: MarketOverviewMetricsCell.cellHeight
                        )
                    ]
            )

            sections.append(metricsSection)

            let marketTops = viewModel.marketTops

            for viewItem in viewItems {
                let listType = viewItem.listType
                let currentMarketTopIndex = viewModel.marketTopIndex(listType: listType)

                let headerSection = Section(
                        id: "header_\(listType.rawValue)",
                        footerState: .margin(height: .margin12),
                        rows: [
                            Row<MarketOverviewHeaderCell>(
                                    id: "header_\(listType.rawValue)",
                                    height: .heightCell48,
                                    bind: { [weak self] cell, _ in
                                        cell.set(backgroundStyle: .transparent)

                                        cell.set(values: marketTops)
                                        cell.setSelected(index: currentMarketTopIndex)
                                        cell.onSelect = { index in
                                            self?.viewModel.onSelect(marketTopIndex: index, listType: listType)
                                        }

                                        cell.titleImage = UIImage(named: viewItem.imageName)
                                        cell.title = viewItem.title
                                    }
                            )
                        ]
                )

                let listSection = Section(
                        id: viewItem.listType.rawValue,
                        footerState: .margin(height: .margin24),
                        rows: rows(listViewItems: viewItem.listViewItems) + [
                            seeAllRow(
                                    id: "\(viewItem.listType.rawValue)-see-all",
                                    action: { [weak self] in
                                        self?.didTapSeeAll(listType: viewItem.listType)
                                    }
                            )
                        ]
                )

                sections.append(headerSection)
                sections.append(listSection)
            }
        }

        return sections
    }

}

extension MarketOverviewTopCoinsDataSource: IMarketOverviewDataSource {
    var updateDriver: Driver<()> {
        statusRelay.asDriver(onErrorJustReturn: ())
    }

    func refresh() {
        viewModel.refresh()
    }

}

import UIKit
import RxSwift
import RxCocoa
import SectionsTableView
import Chart
import ComponentKit

protocol IMarketOverviewTopCoinsViewModel {
    var statusDriver: Driver<DataStatus<[MarketOverviewTopCoinsViewModel.TopViewItem]>> { get }
    var marketTops: [String] { get }
    func marketTop(listType: MarketOverviewTopCoinsService.ListType) -> MarketModule.MarketTop
    func marketTopIndex(listType: MarketOverviewTopCoinsService.ListType) -> Int
    func onSelect(marketTopIndex: Int, listType: MarketOverviewTopCoinsService.ListType)
    func refresh()

    func collection(uid: String) -> NftCollection?
}

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

    private let viewModel: IMarketOverviewTopCoinsViewModel

    private var topViewItems: [MarketOverviewTopCoinsViewModel.TopViewItem] = []

    private let marketMetricsCell = MarketOverviewMetricsCell(chartConfiguration: ChartConfiguration.smallChart)

    init(viewModel: IMarketOverviewTopCoinsViewModel) {
        self.viewModel = viewModel

        subscribe(disposeBag, viewModel.statusDriver) { [weak self] in self?.sync(status: $0) }
    }

    private func sync(status: DataStatus<[MarketOverviewTopCoinsViewModel.TopViewItem]>) {
        self.status = status.map { [weak self] viewItems in
            self?.topViewItems = viewItems

            return sections
        }
    }

    private func row(listType: MarketOverviewTopCoinsService.ListType, listViewItem: MarketModule.ListViewItem, isFirst: Bool) -> RowProtocol {
        Row<G14Cell>(
                id: "\(listViewItem.uid ?? "")-\(listViewItem.name)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst)
                    MarketModule.bind(cell: cell, viewItem: listViewItem)
                },
                action: { [weak self] _ in
                    self?.onSelect(listType: listType, listViewItem: listViewItem)
                })
    }

    private func rows(listType: MarketOverviewTopCoinsService.ListType, listViewItems: [MarketModule.ListViewItem]) -> [RowProtocol] {
        listViewItems.enumerated().map { index, listViewItem in
            row(listType: listType, listViewItem: listViewItem, isFirst: index == 0)
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
        if case .topCollections = listType {
            let module = MarketNftTopCollectionsModule.viewController()
            parentNavigationController?.present(module, animated: true)
        } else {
            let module = MarketTopModule.viewController(
                    marketTop: viewModel.marketTop(listType: listType),
                    sortingField: listType.sortingField,
                    marketField: listType.marketField
            )
            parentNavigationController?.present(module, animated: true)
        }
    }

    private func onSelect(listType: MarketOverviewTopCoinsService.ListType, listViewItem: MarketModule.ListViewItem) {
        if case .topCollections = listType, let uid = listViewItem.uid, let collection = viewModel.collection(uid: uid) {
            let module = NftCollectionModule.viewController(collection: collection)
            parentNavigationController?.pushViewController(module, animated: true)
        } else if let uid = listViewItem.uid, let module = CoinPageModule.viewController(coinUid: uid) {
            parentNavigationController?.present(module, animated: true)
        }
    }

    private var sections: [SectionProtocol] {
        var sections = [SectionProtocol]()

        let marketTops = viewModel.marketTops

        for viewItem in topViewItems {
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

                                    cell.buttonMode = viewItem.listType == .topCollections ? .none : .selector
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
                    rows: rows(listType: viewItem.listType, listViewItems: viewItem.listViewItems) + [
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

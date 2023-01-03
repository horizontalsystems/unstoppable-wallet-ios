import UIKit
import RxSwift
import RxCocoa
import SectionsTableView
import Chart
import ComponentKit

protocol IBaseMarketOverviewTopListViewModel {
    var listViewItemsDriver: Driver<[MarketModule.ListViewItem]?> { get }
    var selectorTitles: [String] { get }
    var selectorIndex: Int { get }
    func onSelect(selectorIndex: Int)
}

class BaseMarketOverviewTopListDataSource {
    private let topListViewModel: IBaseMarketOverviewTopListViewModel
    weak var presentDelegate: IPresentDelegate?
    private let rightSelectorMode: MarketOverviewHeaderCell.ButtonMode
    private let imageName: String
    private let title: String
    private let disposeBag = DisposeBag()

    private let listViewItemsRelay = BehaviorRelay<[MarketModule.ListViewItem]?>(value: nil)

    init(topListViewModel: IBaseMarketOverviewTopListViewModel, presentDelegate: IPresentDelegate, rightSelectorMode: MarketOverviewHeaderCell.ButtonMode, imageName: String, title: String) {
        self.topListViewModel = topListViewModel
        self.presentDelegate = presentDelegate
        self.rightSelectorMode = rightSelectorMode
        self.imageName = imageName
        self.title = title

        subscribe(disposeBag, topListViewModel.listViewItemsDriver) { [weak self] listViewItems in
            self?.listViewItemsRelay.accept(listViewItems)
        }
    }

    private func rows(tableView: SectionsTableView, listViewItems: [MarketModule.ListViewItem]) -> [RowProtocol] {
        listViewItems.enumerated().map { index, listViewItem in
            MarketModule.marketListCell(
                    tableView: tableView,
                    backgroundStyle: .lawrence,
                    listViewItem: listViewItem,
                    isFirst: index == 0,
                    isLast: false,
                    rowActionProvider: nil,
                    action:  { [weak self] in
                        self?.onSelect(listViewItem: listViewItem)
                    })
        }
    }

    private func seeAllRow(tableView: SectionsTableView, id: String, action: @escaping () -> ()) -> RowProtocol {
        tableView.universalRow48(
                id: id,
                title: .body("market.top.section.header.see_all".localized),
                accessoryType: .disclosure,
                autoDeselect: true,
                isLast: true,
                action: action
        )
    }

    func didTapSeeAll() {
    }

    func onSelect(listViewItem: MarketModule.ListViewItem) {
    }

}

extension BaseMarketOverviewTopListDataSource: IMarketOverviewDataSource {

    var isReady: Bool {
        listViewItemsRelay.value != nil
    }

    var updateObservable: Observable<()> {
        listViewItemsRelay.map { _ in () }
    }

    private func bind(cell: MarketOverviewHeaderCell) {
        cell.set(backgroundStyle: .transparent)

        cell.buttonMode = rightSelectorMode
        cell.set(values: topListViewModel.selectorTitles)
        cell.setSelected(index: topListViewModel.selectorIndex)
        cell.onSelect = { [weak self] index in
            self?.topListViewModel.onSelect(selectorIndex: index)
        }
        cell.onTapTitle = { [weak self] in self?.didTapSeeAll() }

        cell.titleImage = UIImage(named: imageName)
        cell.title = title
    }

    func sections(tableView: SectionsTableView) -> [SectionProtocol] {
        guard let listViewItems = listViewItemsRelay.value else {
            return []
        }

        var sections = [SectionProtocol]()

        let headerSection = Section(
                id: "header_\(title)",
                footerState: .margin(height: .margin8),
                rows: [
                    Row<MarketOverviewHeaderCell>(
                            id: "header_\(title)",
                            height: .heightCell48,
                            bind: { [weak self] cell, _ in
                                self?.bind(cell: cell)
                            }
                    )
                ]
        )

        let listSection = Section(
                id: title,
                footerState: .margin(height: .margin24),
                rows: rows(tableView: tableView, listViewItems: listViewItems) + [
                    seeAllRow(
                            tableView: tableView,
                            id: "\(title)-see-all",
                            action: { [weak self] in
                                self?.didTapSeeAll()
                            }
                    )
                ]
        )

        sections.append(headerSection)
        sections.append(listSection)

        return sections
    }

}

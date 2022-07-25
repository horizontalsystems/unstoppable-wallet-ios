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

    private func rows(tableView: UITableView, listViewItems: [MarketModule.ListViewItem]) -> [RowProtocol] {
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

    private func seeAllRow(tableView: UITableView, id: String, action: @escaping () -> ()) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.text, .image20],
                tableView: tableView,
                id: id,
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isLast: true)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = "market.top.section.header.see_all".localized
                    }
                    cell.bind(index: 1) { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
                    }
                },
                action: {
                    action()
                }
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

    func sections(tableView: UITableView) -> [SectionProtocol] {
        guard let listViewItems = listViewItemsRelay.value else {
            return []
        }

        var sections = [SectionProtocol]()

        let headerSection = Section(
                id: "header_\(title)",
                footerState: .margin(height: .margin12),
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

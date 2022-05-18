import UIKit
import RxSwift
import RxCocoa
import SectionsTableView
import Chart
import ComponentKit

protocol IBaseMarketOverviewTopListViewModel {
    var viewItem: BaseMarketOverviewTopListDataSource.ViewItem? { get }
    var selectorTitles: [String] { get }

    var selectorIndex: Int { get }

    func onSelect(selectorIndex: Int)
    func refresh()
}

class BaseMarketOverviewTopListDataSource {
    private let disposeBag = DisposeBag()

    var presentDelegate: IPresentDelegate

    var status: DataStatus<[SectionProtocol]> = .loading {
        didSet { statusRelay.accept(()) }
    }
    private let statusRelay = PublishRelay<()>()

    private let viewModel: IBaseMarketOverviewTopListViewModel

    init(viewModel: IBaseMarketOverviewTopListViewModel, presentDelegate: IPresentDelegate) {
        self.viewModel = viewModel
        self.presentDelegate = presentDelegate
    }

    private func rows(tableView: UITableView, listViewItems: [MarketModule.ListViewItem]) -> [RowProtocol] {
        listViewItems.enumerated().map { index, listViewItem in
            MarketModule.marketListCell(
                    tableView: tableView,
                    backgroundStyle: .lawrence,
                    listViewItem: listViewItem,
                    isFirst: index == 0,
                    rowActionProvider: nil,
                    action:  {[weak self] in
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
                        component.set(style: .b2)
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

    func sections(tableView: UITableView) -> [SectionProtocol] {
        guard let topViewItem = viewModel.viewItem else {
            return []
        }

        var sections = [SectionProtocol]()

        let marketTops = viewModel.selectorTitles

        let currentMarketTopIndex = viewModel.selectorIndex

        let headerSection = Section(
                id: "header_\(topViewItem.title)",
                footerState: .margin(height: .margin12),
                rows: [
                    Row<MarketOverviewHeaderCell>(
                            id: "header_\(topViewItem.title)",
                            height: .heightCell48,
                            bind: { [weak self] cell, _ in
                                cell.set(backgroundStyle: .transparent)

                                cell.buttonMode = topViewItem.rightSelectorMode
                                cell.set(values: marketTops)
                                cell.setSelected(index: currentMarketTopIndex)
                                cell.onSelect = { index in
                                    self?.viewModel.onSelect(selectorIndex: index)
                                }

                                cell.titleImage = UIImage(named: topViewItem.imageName)
                                cell.title = topViewItem.title
                            }
                    )
                ]
        )

        let listSection = Section(
                id: topViewItem.title,
                footerState: .margin(height: .margin24),
                rows: rows(tableView: tableView, listViewItems: topViewItem.listViewItems) + [
                    seeAllRow(
                            tableView: tableView,
                            id: "\(topViewItem.title)-see-all",
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

extension BaseMarketOverviewTopListDataSource {

    struct ViewItem {
        let rightSelectorMode: MarketOverviewHeaderCell.ButtonMode
        let imageName: String
        let title: String

        let listViewItems: [MarketModule.ListViewItem]
    }

}

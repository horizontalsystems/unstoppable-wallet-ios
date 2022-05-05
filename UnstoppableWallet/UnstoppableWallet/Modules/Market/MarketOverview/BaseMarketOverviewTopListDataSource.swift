import UIKit
import RxSwift
import RxCocoa
import SectionsTableView
import Chart
import ComponentKit

protocol IBaseMarketOverviewTopListViewModel {
    var statusDriver: Driver<DataStatus<BaseMarketOverviewTopListDataSource.ViewItem>> { get }
    var selectorValues: [String] { get }

    var selectorIndex: Int { get }

    func onSelect(selectorIndex: Int)
    func refresh()
}

class BaseMarketOverviewTopListDataSource {
    private let disposeBag = DisposeBag()

    weak var parentNavigationController: UINavigationController?
    var status: DataStatus<[SectionProtocol]> = .loading {
        didSet { statusRelay.accept(()) }
    }
    private let statusRelay = PublishRelay<()>()

    private let viewModel: IBaseMarketOverviewTopListViewModel

    private var topViewItem: ViewItem?

    init(viewModel: IBaseMarketOverviewTopListViewModel) {
        self.viewModel = viewModel

        subscribe(disposeBag, viewModel.statusDriver) { [weak self] in self?.sync(status: $0) }
    }

    private func sync(status: DataStatus<ViewItem>) {
        self.status = status.map { [weak self] viewItem in
            self?.topViewItem = viewItem

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
//        return CellBuilder.selectableRow(
//                elements: [.text, .image20],
//                tableView: tableView,
//                id: fundViewItem.uid,
//                height: .heightCell48,
//                autoDeselect: true,
//                bind: { [weak self] cell in
//                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
//                    self?.bind(cell: cell, fundViewItem: fundViewItem)
//
//                    cell.bind(index: 3) { (component: ImageComponent) in
//                        component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
//                    }
//                },
//                action: { [weak self] in
//                    self?.urlManager.open(url: fundViewItem.url, from: self)
//                }
//        )
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

    func didTapSeeAll() {
    }

    func onSelect(listViewItem: MarketModule.ListViewItem) {
    }

    private var sections: [SectionProtocol] {
        guard let topViewItem = topViewItem else {
            return []
        }

        var sections = [SectionProtocol]()

        let marketTops = viewModel.selectorValues

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
                rows: rows(listViewItems: topViewItem.listViewItems) + [
                    seeAllRow(
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
extension BaseMarketOverviewTopListDataSource: IMarketOverviewDataSource {

    var updateDriver: Driver<()> {
        statusRelay.asDriver(onErrorJustReturn: ())
    }

    func refresh() {
        viewModel.refresh()
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

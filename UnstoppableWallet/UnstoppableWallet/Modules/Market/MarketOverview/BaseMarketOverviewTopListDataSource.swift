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

    var presentDelegate: IPresentDelegate

    weak var tableView: UITableView?
    var status: DataStatus<[SectionProtocol]> = .loading {
        didSet { statusRelay.accept(()) }
    }
    private let statusRelay = PublishRelay<()>()

    private let viewModel: IBaseMarketOverviewTopListViewModel

    private var topViewItem: ViewItem?

    init(viewModel: IBaseMarketOverviewTopListViewModel, presentDelegate: IPresentDelegate) {
        self.viewModel = viewModel
        self.presentDelegate = presentDelegate

        subscribe(disposeBag, viewModel.statusDriver) { [weak self] in self?.sync(status: $0) }
    }

    private func sync(status: DataStatus<ViewItem>) {
        self.status = status.map { [weak self] viewItem in
            self?.topViewItem = viewItem

            return sections
        }
    }

    private func row(listViewItem: MarketModule.ListViewItem, isFirst: Bool) -> RowProtocol {
        guard let tableView = tableView else {
            fatalError("I need tableView :(")
        }

        return CellBuilder.selectableRow(
                elements: [.image24, .multiText, .multiText],
                tableView: tableView,
                id: "\(listViewItem.uid ?? "")-\(listViewItem.name)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        component.imageView.clipsToBounds = true
                        component.imageView.cornerRadius = listViewItem.iconShape == .square ? .cornerRadius4 : .cornerRadius12
                        component.setImage(urlString: listViewItem.iconUrl, placeholder: UIImage(named: listViewItem.iconPlaceholderName))
                    }
                    cell.bind(index: 1) { (component: MultiTextComponent) in
                        component.set(style: .m3)
                        component.title.set(style: .b2)
                        component.subtitle.set(style: .d1)

                        component.title.text = listViewItem.name
                        component.subtitle.text = listViewItem.code
                        component.subtitleBadge.text = listViewItem.rank
                    }
                    cell.bind(index: 2) { (component: MultiTextComponent) in
                        component.titleSpacingView.isHidden = true
                        component.set(style: .m1)
                        component.title.set(style: .b2)
                        component.subtitle.set(style: .d1)

                        component.title.textAlignment = .right
                        component.title.text = listViewItem.price

                        let marketFieldData = MarketModule.marketFieldPreference(dataValue: listViewItem.dataValue)
                        component.subtitle.textAlignment = .right
                        component.subtitle.textColor = marketFieldData.color
                        component.subtitle.text = marketFieldData.value
                    }
                },
                action: {[weak self] in
                    self?.onSelect(listViewItem: listViewItem)
                }
        )
    }

    private func rows(listViewItems: [MarketModule.ListViewItem]) -> [RowProtocol] {
        listViewItems.enumerated().map { index, listViewItem in
            row(listViewItem: listViewItem, isFirst: index == 0)
        }
    }

    private func seeAllRow(id: String, action: @escaping () -> ()) -> RowProtocol {
        guard let tableView = tableView else {
            fatalError("I need tableView")
        }

        return CellBuilder.selectableRow(
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

import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import HUD

class MarketDiscoveryViewController: ThemeViewController {
    private let marketViewModel: MarketViewModel
    private let viewModel: MarketDiscoveryViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .plain)

    private let filterHeaderView = MarketDiscoveryFilterHeaderView()
    private let sectionHeaderView = MarketListHeaderView()

    weak var parentNavigationController: UINavigationController?

    private var state: MarketDiscoveryViewModel.State = .loading

    init(marketViewModel: MarketViewModel, viewModel: MarketDiscoveryViewModel) {
        self.marketViewModel = marketViewModel
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerHeaderFooter(forClass: MarketListHeaderView.self)
        tableView.registerCell(forClass: G14Cell.self)
        tableView.registerCell(forClass: SpinnerCell.self)
        tableView.registerCell(forClass: ErrorCell.self)

        tableView.sectionDataSource = self

        sectionHeaderView.onTapSortField = { [weak self] in
            self?.onTapSortingField()
        }
        sectionHeaderView.onSelect = { [weak self] field in
            self?.viewModel.set(marketField: field)
        }

        filterHeaderView.onSelect = { [weak self] filterIndex in
            self?.viewModel.setFilter(at: filterIndex)
        }

        subscribe(disposeBag, viewModel.stateDriver) { [weak self] state in
            self?.state = state
            self?.tableView.reload()
        }
        subscribe(disposeBag, viewModel.sortingFieldTitleDriver) { [weak self] title in
            self?.sectionHeaderView.setSortingField(title: title)
        }
        subscribe(disposeBag, viewModel.marketFieldDriver) { [weak self] marketField in
            self?.sectionHeaderView.setMarketField(field: marketField)
        }
        subscribe(disposeBag, viewModel.selectedFilterIndexDriver) { [weak self] index in
            self?.filterHeaderView.setSelected(index: index)
        }
        subscribe(disposeBag, marketViewModel.discoveryListTypeSignal) { [weak self] in self?.handle(listType: $0) }
    }

    private func onTapSortingField() {
        let alertController = AlertRouter.module(
                title: "market.sort_by".localized,
                viewItems: viewModel.sortingFieldViewItems.map { viewItem in
                    AlertViewItem(
                            text: viewItem.title,
                            selected: viewItem.selected
                    )
                }
        ) { [weak self] index in
            self?.viewModel.setSortingField(at: index)
        }

        present(alertController, animated: true)
    }

    private func row(viewItem: MarketModule.ViewItem, isLast: Bool) -> RowProtocol {
        switch viewItem.score {
        case .none:
            return Row<G14Cell>(
                    id: viewItem.coinCode,
                    height: .heightDoubleLineCell,
                    autoDeselect: true,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .transparent, isLast: isLast)
                        MarketModule.bind(cell: cell, viewItem: viewItem)
                    },
                    action: { [weak self] _ in
                        self?.onSelect(viewItem: viewItem)
                    })
        default:
            return Row<G14Cell>(
                    id: viewItem.coinCode,
                    height: .heightDoubleLineCell,
                    autoDeselect: true,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .transparent, isLast: isLast)
                        MarketModule.bind(cell: cell, viewItem: viewItem)
                    },
                    action: { [weak self] _ in
                        self?.onSelect(viewItem: viewItem)
                    })
        }
    }

    private func onSelect(viewItem: MarketModule.ViewItem) {
        let viewController = ChartRouter.module(launchMode: .partial(coinCode: viewItem.coinCode, coinTitle: viewItem.coinName, coinType: nil))
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

    private func handle(listType: MarketModule.ListType) {
        viewModel.set(listType: listType)
    }

}

extension MarketDiscoveryViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var rows = [RowProtocol]()

        if case .loaded(let viewItems) = state {
            rows = viewItems.enumerated().map { row(viewItem: $1, isLast: $0 == viewItems.count - 1) }
        }

        var sections: [SectionProtocol] = [
            Section(
                    id: "filter",
                    headerState: .static(view: filterHeaderView, height: MarketDiscoveryFilterHeaderView.headerHeight)
            ),
            Section(id: "tokens",
                    headerState: .static(view: sectionHeaderView, height: MarketListHeaderView.height),
                    rows: rows
            )
        ]

        switch state {
        case .loading:
            sections.append(
                    Section(
                            id: "spinner",
                            rows: [
                                Row<SpinnerCell>(
                                        id: "spinner",
                                        height: 120
                                )
                            ]
                    )
            )

        case .error(let errorDescription):
            sections.append(
                    Section(
                            id: "error",
                            rows: [
                                Row<ErrorCell>(
                                        id: "error",
                                        height: 120,
                                        bind: { cell, _ in
                                            cell.errorText = errorDescription
                                        }
                                )
                            ]
                    )
            )

        default: ()
        }

        return sections
    }

}

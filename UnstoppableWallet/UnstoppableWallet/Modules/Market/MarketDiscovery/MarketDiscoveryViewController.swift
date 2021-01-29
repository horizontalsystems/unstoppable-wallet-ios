import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import HUD

class MarketDiscoveryViewController: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .plain)
    private let spinner = HUDActivityView.create(with: .large48)

    private let filterHeaderView = MarketDiscoveryFilterHeaderView()

    private let viewModel: MarketDiscoveryViewModel
    private let sectionHeaderView = MarketListHeaderView()

    var pushController: ((UIViewController) -> ())?

    private var viewItems = [MarketModule.MarketViewItem]()

    init(viewModel: MarketDiscoveryViewModel) {
        self.viewModel = viewModel

        super.init()

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
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
        tableView.registerCell(forClass: GB14Cell.self)

        tableView.sectionDataSource = self

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }
        sync(isLoading: false)

        sectionHeaderView.setSortingField(title: viewModel.sortingFieldTitle)
        sectionHeaderView.onTapSortField = { [weak self] in
            self?.onTapSortingField()
        }
        sectionHeaderView.onSelect = { [weak self] field in
            self?.viewModel.set(marketField: field)
        }

        filterHeaderView.onSelect = { [weak self] filterIndex in
            self?.viewModel.setFilter(at: filterIndex )
        }

        tableView.buildSections()
    }

    private func sync(viewItems: [MarketModule.MarketViewItem]) {
        self.viewItems = viewItems

        tableView.reload()
    }

    private func sync(isLoading: Bool) {
        guard isLoading && tableView.visibleCells.isEmpty else {
            spinner.isHidden = true
            spinner.stopAnimating()

            return
        }

        spinner.isHidden = false
        spinner.startAnimating()
    }

    private func onTapSortingField() {
        let alertController = AlertRouter.module(
                title: "market.sort_by".localized,
                viewItems: viewModel.sortingFields.map { item in
                    AlertViewItem(
                            text: item,
                            selected: item == viewModel.sortingFieldTitle
                    )
                }
        ) { [weak self] index in
            self?.viewModel.setSortingField(at: index)
        }

        present(alertController, animated: true)
    }

    private func row(viewItem: MarketModule.MarketViewItem, isLast: Bool) -> RowProtocol {
        Row<GB14Cell>(
                id: viewItem.coinCode,
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .claude, isLast: isLast)
                    MarketModule.bind(cell: cell, viewItem: viewItem)
                },
                action: { [weak self] _ in
                    self?.onSelect(viewItem: viewItem)
                }
        )
    }

    private func onSelect(viewItem: MarketModule.MarketViewItem) {
        let viewController = ChartRouter.module(launchMode: .partial(coinCode: viewItem.coinCode, coinTitle: viewItem.coinName, coinType: viewItem.coinType))
        pushController?(viewController)
    }

}

extension MarketDiscoveryViewController {

    func setPreferences(for type: MarketOverviewViewModel.SectionType) {
        viewModel.setPreferences(for: type)
        sectionHeaderView.setMarketField(field: viewModel.marketField)
    }

}

extension MarketDiscoveryViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let filterHeaderState: ViewState<MarketDiscoveryFilterHeaderView> = .static(view: filterHeaderView, height: MarketDiscoveryFilterHeaderView.headerHeight)

        sectionHeaderView.setSortingField(title: viewModel.sortingFieldTitle)
        let headerState: ViewState<MarketListHeaderView> = .static(view: sectionHeaderView, height: MarketListHeaderView.height)

        return [
            Section(id: "filter",
                    headerState: filterHeaderState,
                    rows: []),
            Section(id: "tokens",
                    headerState: headerState,
                    rows: viewItems.enumerated().map { row(viewItem: $1, isLast: $0 == viewItems.count - 1) })
        ]
    }

}

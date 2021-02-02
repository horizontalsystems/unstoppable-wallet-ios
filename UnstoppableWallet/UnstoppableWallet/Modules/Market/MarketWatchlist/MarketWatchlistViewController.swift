import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import HUD

class MarketWatchlistViewController: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .plain)
    private let spinner = HUDActivityView.create(with: .large48)

    private let viewModel: MarketWatchlistViewModel

    weak var parentNavigationController: UINavigationController?

    private var viewItems = [MarketModule.ViewItem]()

    init(viewModel: MarketWatchlistViewModel) {
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
        tableView.registerCell(forClass: G14Cell.self)

        tableView.sectionDataSource = self

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }
        sync(isLoading: false)

        tableView.buildSections()
    }

    private func sync(viewItems: [MarketModule.ViewItem]) {
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

    private func bindHeader(headerView: MarketListHeaderView) {
        headerView.setSortingField(title: viewModel.sortingFieldTitle)
        headerView.onTapSortField = { [weak self] in
            self?.onTapSortingField()
        }
        headerView.onSelect = { [weak self] field in
            self?.viewModel.set(marketField: field)
        }
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

    private func row(viewItem: MarketModule.ViewItem, isLast: Bool) -> RowProtocol {
        Row<G14Cell>(
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

    private func onSelect(viewItem: MarketModule.ViewItem) {
        let viewController = ChartRouter.module(launchMode: .partial(coinCode: viewItem.coinCode, coinTitle: viewItem.coinName, coinType: nil))
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

}

extension MarketWatchlistViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let headerState: ViewState<MarketListHeaderView> = .cellType(
                hash: "section_header",
                binder: { [weak self] view in
                    self?.bindHeader(headerView: view)
                },
                dynamicHeight: { _ in
                    MarketListHeaderView.height
                })

        return [Section(id: "tokens",
                headerState: headerState,
                rows: viewItems.enumerated().map { row(viewItem: $1, isLast: $0 == viewItems.count - 1) })]
    }

}

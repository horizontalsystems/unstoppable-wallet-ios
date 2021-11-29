import UIKit
import RxSwift
import RxCocoa
import ThemeKit
import SectionsTableView
import ComponentKit
import HUD

protocol IMarketListViewModel {
    var viewItemDataDriver: Driver<MarketModule.ListViewItemData?> { get }
    var loadingDriver: Driver<Bool> { get }
    var errorDriver: Driver<String?> { get }
    var scrollToTopSignal: Signal<()> { get }
    func isFavorite(index: Int) -> Bool?
    func favorite(index: Int)
    func unfavorite(index: Int)
    func refresh()
}

class MarketListViewController: ThemeViewController {
    private let listViewModel: IMarketListViewModel
    private let disposeBag = DisposeBag()

    let tableView = SectionsTableView(style: .plain)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = MarketListErrorView()
    private let refreshControl = UIRefreshControl()

    private var viewItems: [MarketModule.ListViewItem]?

    var viewController: UIViewController? { self }
    var headerView: UITableViewHeaderFooterView? { nil }
    var emptyView: UIView? { nil }
    var refreshEnabled: Bool { true }
    func topSections(loaded: Bool) -> [SectionProtocol] { [] }

    init(listViewModel: IMarketListViewModel) {
        self.listViewModel = listViewModel

        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl.tintColor = .themeLeah
        refreshControl.alpha = 0.6
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: G14Cell.self)

        if let emptyView = emptyView {
            view.addSubview(emptyView)
            emptyView.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview().inset(CGFloat.margin48)
                maker.centerY.equalToSuperview()
            }
        }

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.startAnimating()

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        errorView.onTapRetry = { [weak self] in self?.refresh() }

        subscribe(disposeBag, listViewModel.viewItemDataDriver) { [weak self] in self?.sync(viewItemData: $0) }
        subscribe(disposeBag, listViewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, listViewModel.errorDriver) { [weak self] error in
            if let error = error {
                self?.errorView.text = error
                self?.errorView.isHidden = false
            } else {
                self?.errorView.isHidden = true
            }
        }
        subscribe(disposeBag, listViewModel.scrollToTopSignal) { [weak self] in self?.scrollToTop() }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if refreshEnabled {
            tableView.refreshControl = refreshControl
        }
    }

    func refresh() {
        listViewModel.refresh()
    }

    @objc private func onRefresh() {
        refresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    private func sync(viewItemData: MarketModule.ListViewItemData?) {
        viewItems = viewItemData?.viewItems

        if let viewItems = viewItems, viewItems.isEmpty {
            emptyView?.isHidden = false
        } else {
            emptyView?.isHidden = true
        }

        if let viewItems = viewItems, !viewItems.isEmpty {
            tableView.bounces = true
        } else {
            tableView.bounces = false
        }

        if let viewItemData = viewItemData {
            tableView.reload(animated: viewItemData.softUpdate)
        } else {
            tableView.reload()
        }
    }

    private func onSelect(viewItem: MarketModule.ListViewItem) {
        guard let uid = viewItem.uid, let module = CoinPageModule.viewController(coinUid: uid) else {
            HudHelper.instance.showAttention(title: "market.coin_not_supported_yet".localized)
            return
        }

        viewController?.present(module, animated: true)
    }

    private func rowActions(index: Int) -> [RowAction] {
        guard let isFavorite = listViewModel.isFavorite(index: index) else {
            return []
        }

        let type: RowActionType
        let iconName: String
        let action: (UITableViewCell?) -> ()

        if isFavorite {
            type = .destructive
            iconName = "star_off_24"
            action = { [weak self] _ in
                self?.listViewModel.unfavorite(index: index)
            }
        } else {
            type = .additive
            iconName = "star_24"
            action = { [weak self] _ in
                self?.listViewModel.favorite(index: index)
            }
        }

        return [
            RowAction(
                    pattern: .icon(image: UIImage(named: iconName)?.withTintColor(type.iconColor), background: type.backgroundColor),
                    action: action
            )
        ]
    }

    private func scrollToTop() {
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
    }

}

extension MarketListViewController: SectionsDataSource {

    private func row(viewItem: MarketModule.ListViewItem, index: Int, isLast: Bool) -> RowProtocol {
        Row<G14Cell>(
                id: "\(viewItem.uid ?? "")-\(viewItem.name)",
                hash: "\(viewItem.dataValue)-\(viewItem.price)-\(isLast)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                rowActionProvider: { [weak self] in
                    self?.rowActions(index: index) ?? []
                },
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                    MarketModule.bind(cell: cell, viewItem: viewItem)
                },
                action: { [weak self] _ in
                    self?.onSelect(viewItem: viewItem)
                })
    }

    func buildSections() -> [SectionProtocol] {
        let headerState: ViewState<UITableViewHeaderFooterView>

        if let headerView = headerView, let viewItems = viewItems, !viewItems.isEmpty {
            headerState = .static(view: headerView, height: .heightSingleLineCell)
        } else {
            headerState = .margin(height: 0)
        }

        return topSections(loaded: viewItems != nil) + [
            Section(
                    id: "coins",
                    headerState: headerState,
                    footerState: .marginColor(height: .margin32, color: .clear) ,
                    rows: viewItems.map { viewItems in
                        viewItems.enumerated().map { row(viewItem: $1, index: $0, isLast: $0 == viewItems.count - 1) }
                    } ?? []
            )
        ]
    }

}

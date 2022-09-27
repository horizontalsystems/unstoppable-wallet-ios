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
    var syncErrorDriver: Driver<Bool> { get }
    var scrollToTopSignal: Signal<()> { get }
    func refresh()
}

class MarketListViewController: ThemeViewController {
    private let listViewModel: IMarketListViewModel
    private let disposeBag = DisposeBag()

    let tableView = SectionsTableView(style: .plain)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()
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

        if let watchViewModel = listViewModel as? IMarketListWatchViewModel {
            subscribe(disposeBag, watchViewModel.favoriteDriver) { [weak self] in self?.showAddedToWatchlist() }
            subscribe(disposeBag, watchViewModel.unfavoriteDriver) { [weak self] in self?.showRemovedFromWatchlist() }
            subscribe(disposeBag, watchViewModel.failDriver) { error in HudHelper.instance.show(banner: .error(string: error.localized)) }
        }
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

        if let emptyView = emptyView {
            view.addSubview(emptyView)
            emptyView.snp.makeConstraints { maker in
                maker.edges.equalTo(view.safeAreaLayoutGuide)
            }
        }

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.startAnimating()

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        errorView.configureSyncError(action: { [weak self] in self?.onRetry() })

        subscribe(disposeBag, listViewModel.viewItemDataDriver) { [weak self] in self?.sync(viewItemData: $0) }
        subscribe(disposeBag, listViewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, listViewModel.syncErrorDriver) { [weak self] visible in
            self?.errorView.isHidden = !visible
        }
        subscribe(disposeBag, listViewModel.scrollToTopSignal) { [weak self] in self?.scrollToTop() }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if refreshEnabled {
            tableView.refreshControl = refreshControl
        }
    }

    @objc private func onRetry() {
        refresh()
    }

    @objc private func onRefresh() {
        refresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    private func refresh() {
        listViewModel.refresh()
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

    func onSelect(viewItem: MarketModule.ListViewItem) {
        guard let uid = viewItem.uid, let module = CoinPageModule.viewController(coinUid: uid) else {
            HudHelper.instance.show(banner: .attention(string: "market.project_has_no_coin".localized))
            return
        }

        viewController?.present(module, animated: true)
    }

    private func rowActions(index: Int) -> [RowAction] {
        guard let watchListViewModel = listViewModel as? IMarketListWatchViewModel else {
            return []
        }

        guard let isFavorite = watchListViewModel.isFavorite(index: index) else {
            return []
        }

        let type: RowActionType
        let iconName: String
        let action: (UITableViewCell?) -> ()

        if isFavorite {
            type = .destructive
            iconName = "star_off_24"
            action = { _ in
                watchListViewModel.unfavorite(index: index)
            }
        } else {
            type = .additive
            iconName = "star_24"
            action = { _ in
                watchListViewModel.favorite(index: index)
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

    func showAddedToWatchlist() {
        HudHelper.instance.show(banner: .addedToWatchlist)
    }

    func showRemovedFromWatchlist() {
        HudHelper.instance.show(banner: .removedFromWatchlist)
    }

}

extension MarketListViewController: SectionsDataSource {

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
                        viewItems.enumerated().map { index, viewItem in
                            MarketModule.marketListCell(
                                    tableView: tableView,
                                    backgroundStyle: .transparent,
                                    listViewItem: viewItem,
                                    isFirst: false,
                                    isLast: index == viewItems.count - 1,
                                    rowActionProvider: { [weak self] in
                                        self?.rowActions(index: index) ?? []
                                    },
                                    action: { [weak self] in
                                        self?.onSelect(viewItem: viewItem)
                                    }
                            )
                        }
                    } ?? []
            )
        ]
    }

}

import Combine
import ComponentKit
import MarketKit
import SectionsTableView
import SnapKit
import ThemeKit
import UIKit

class MarketViewController: ThemeSearchViewController {
    private let viewModel = MarketViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let tabsView = FilterView(buttonStyle: .tab)
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

    private var marketOverviewViewController: MarketOverviewViewController?
    private let postViewController: MarketPostViewController
    private let watchlistViewController: MarketWatchlistViewController

    private let tableView = SectionsTableView(style: .plain)
    private let notFoundPlaceholder = PlaceholderView(layoutType: .keyboard)

    private var state: MarketViewModel.State = .idle

    init() {
        postViewController = MarketPostModule.viewController()
        watchlistViewController = MarketWatchlistModule.viewController()

        super.init(scrollViews: [tableView], automaticallyShowsCancelButton: true)

        marketOverviewViewController = MarketOverviewModule.viewController(presentDelegate: self)

        tabBarItem = UITabBarItem(title: "market.tab_bar_item".localized, image: UIImage(named: "market_2_24"), tag: 0)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "market.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "manage_2_24"), style: .plain, target: self, action: #selector(onTapFilter))

        view.addSubview(tabsView)
        tabsView.snp.makeConstraints { maker in
            maker.top.equalTo(view.safeAreaLayoutGuide)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(FilterView.height)
        }

        view.addSubview(pageViewController.view)
        pageViewController.view.snp.makeConstraints { maker in
            maker.top.equalTo(tabsView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        tabsView.reload(filters: MarketModule.Tab.allCases.map {
            FilterView.ViewItem.item(title: $0.title)
        })

        tabsView.onSelect = { [weak self] index in
            self?.onSelectTab(index: index)
        }

        postViewController.parentNavigationController = navigationController
        watchlistViewController.parentNavigationController = navigationController

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        tableView.sectionDataSource = self
        tableView.registerHeaderFooter(forClass: TransactionDateHeaderView.self)

        tableView.sectionHeaderTopPadding = 0
        tableView.backgroundColor = .themeTyler
        tableView.separatorStyle = .none

        view.addSubview(notFoundPlaceholder)
        notFoundPlaceholder.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        notFoundPlaceholder.image = UIImage(named: "not_found_48")
        notFoundPlaceholder.text = "market_discovery.not_found".localized

        viewModel.$currentTab
            .sink { [weak self] currentTab in
                self?.tabsView.select(index: MarketModule.Tab.allCases.firstIndex(of: currentTab) ?? 0)
                self?.setViewPager(tab: currentTab)
            }
            .store(in: &cancellables)

        viewModel.$state
            .sink { [weak self] in self?.sync(state: $0) }
            .store(in: &cancellables)

        viewModel.favoritedPublisher
            .sink { HudHelper.instance.show(banner: .addedToWatchlist) }
            .store(in: &cancellables)

        viewModel.unfavoritedPublisher
            .sink { HudHelper.instance.show(banner: .removedFromWatchlist) }
            .store(in: &cancellables)

        $filter
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.sync(filter: $0) }
            .store(in: &cancellables)

        sync(state: viewModel.state)
    }

    override func didPresentSearch() {
        super.didPresentSearch()

        stat(page: .markets, event: .open(page: .marketSearch))
    }

    private func sync(state: MarketViewModel.State) {
        self.state = state

        switch state {
        case .idle:
            tableView.isHidden = true
            notFoundPlaceholder.isHidden = true
        case .placeholder:
            tableView.reload()
            tableView.setContentOffset(CGPoint(x: 0, y: -tableView.adjustedContentInset.top), animated: false)
            tableView.isHidden = false
            notFoundPlaceholder.isHidden = true
        case let .searchResults(fullCoins):
            tableView.reload()
            tableView.isHidden = false
            notFoundPlaceholder.isHidden = !fullCoins.isEmpty
        }
    }

    private func sync(filter: String?) {
        viewModel.onUpdate(searchActive: searchController.isActive, filter: filter ?? "")
    }

    private func onSelectTab(index: Int) {
        guard index < MarketModule.Tab.allCases.count else {
            return
        }

        let tab = MarketModule.Tab.allCases[index]

        viewModel.currentTab = tab

        stat(page: .markets, event: .switchTab(tab: tab.statTab))
    }

    private func setViewPager(tab: MarketModule.Tab) {
        pageViewController.setViewControllers([viewController(tab: tab)], direction: .forward, animated: false)
    }

    private func viewController(tab: MarketModule.Tab) -> UIViewController {
        switch tab {
        case .overview: return marketOverviewViewController ?? UIViewController()
        case .posts: return postViewController
        case .watchlist: return watchlistViewController
        }
    }

    @objc private func onTapFilter() {
        let viewController = MarketAdvancedSearchModule.viewController()
        present(ThemeNavigationController(rootViewController: viewController), animated: true)

        stat(page: .markets, event: .open(page: .advancedSearch))
    }

    func willPresentSearchController(_: UISearchController) {
        viewModel.onUpdate(searchActive: true, filter: filter ?? "")
    }

    func willDismissSearchController(_: UISearchController) {
        viewModel.onUpdate(searchActive: false, filter: filter ?? "")
    }
}

extension MarketViewController: SectionsDataSource {
    private func onSelect(fullCoin: FullCoin, statSection: StatSection) {
        let coinUid = fullCoin.coin.uid

        guard let module = CoinPageModule.viewController(coinUid: coinUid) else {
            return
        }

        DispatchQueue.global().async { [weak self] in
            self?.viewModel.handleOpen(coinUid: coinUid)
        }

        present(module, animated: true)

        stat(page: .marketSearch, section: statSection, event: .openCoin(coinUid: coinUid))
    }

    private func rowActions(coinUid: String) -> [RowAction] {
        let type: RowActionType
        let iconName: String
        let action: (UITableViewCell?) -> Void

        if viewModel.isFavorite(coinUid: coinUid) {
            type = .destructive
            iconName = "star_off_24"
            action = { [weak self] _ in
                self?.viewModel.unfavorite(coinUid: coinUid)
            }
        } else {
            type = .additive
            iconName = "star_24"
            action = { [weak self] _ in
                self?.viewModel.favorite(coinUid: coinUid)
            }
        }

        return [
            RowAction(
                pattern: .icon(image: UIImage(named: iconName)?.withTintColor(type.iconColor), background: type.backgroundColor),
                action: action
            ),
        ]
    }

    private func rows(fullCoins: [FullCoin], statSection: StatSection) -> [RowProtocol] {
        fullCoins.enumerated().map { index, fullCoin in
            let coin = fullCoin.coin
            let isLast = index == fullCoins.count - 1

            return CellBuilderNew.row(
                rootElement: .hStack([
                    .image32 { component in
                        component.setImage(urlString: coin.imageUrl, placeholder: UIImage(named: "placeholder_circle_32"))
                    },
                    .vStackCentered([
                        .text { component in
                            component.font = .body
                            component.textColor = .themeLeah
                            component.text = coin.code
                        },
                        .margin(3),
                        .text { component in
                            component.font = .subhead2
                            component.textColor = .themeGray
                            component.text = coin.name
                        },
                    ]),
                ]),
                tableView: tableView,
                id: "coin_\(coin.uid)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                rowActionProvider: { [weak self] in self?.rowActions(coinUid: coin.uid) ?? [] },
                bind: { cell in
                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                },
                action: { [weak self] in
                    self?.onSelect(fullCoin: fullCoin, statSection: statSection)
                }
            )
        }
    }

    func buildSections() -> [SectionProtocol] {
        switch state {
        case .idle:
            return []
        case let .placeholder(recentFullCoins, popularFullCoins):
            var sections = [SectionProtocol]()

            if !recentFullCoins.isEmpty {
                sections.append(
                    Section(
                        id: "recent",
                        headerState: .cellType(
                            hash: "recent",
                            binder: { (view: TransactionDateHeaderView) in
                                view.text = "market.search.recent".localized
                            },
                            dynamicHeight: { _ in .heightSingleLineCell }
                        ),
                        rows: rows(fullCoins: recentFullCoins, statSection: .recent)
                    )
                )
            }

            if !popularFullCoins.isEmpty {
                sections.append(
                    Section(
                        id: "popular",
                        headerState: .cellType(
                            hash: "popular",
                            binder: { (view: TransactionDateHeaderView) in
                                view.text = "market.search.popular".localized
                            },
                            dynamicHeight: { _ in .heightSingleLineCell }
                        ),
                        rows: rows(fullCoins: popularFullCoins, statSection: .popular)
                    )
                )
            }

            return sections
        case let .searchResults(fullCoins):
            return [
                Section(
                    id: "coins",
                    rows: rows(fullCoins: fullCoins, statSection: .searchResults)
                ),
            ]
        }
    }
}

extension MarketViewController: IPresentDelegate {
    func present(viewController: UIViewController) {
        navigationController?.present(viewController, animated: true)
    }

    func push(viewController: UIViewController) {
        navigationController?.pushViewController(viewController, animated: true)
    }
}

import UIKit
import ThemeKit
import SnapKit
import RxSwift
import RxCocoa

class MarketViewController: ThemeViewController {
    private let viewModel: MarketViewModel
    private let disposeBag = DisposeBag()

    private let tabsView = FilterHeaderView(buttonStyle: .tab)
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

    private var marketOverviewViewController: MarketOverviewViewController?
    private let postViewController: MarketPostViewController
    private let watchlistViewController: MarketWatchlistViewController

    init(viewModel: MarketViewModel) {
        self.viewModel = viewModel

        postViewController = MarketPostModule.viewController()
        watchlistViewController = MarketWatchlistModule.viewController()

        super.init()

        marketOverviewViewController = MarketOverviewModule.viewController(presentDelegate: self)

        tabBarItem = UITabBarItem(title: "market.tab_bar_item".localized, image: UIImage(named: "market_2_24"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(UIView()) // prevent Large Title from Collapsing

        title = "market.title".localized

        view.addSubview(tabsView)
        tabsView.snp.makeConstraints { maker in
            maker.top.equalTo(view.safeAreaLayoutGuide)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(FilterHeaderView.height)
        }

        view.addSubview(pageViewController.view)
        pageViewController.view.snp.makeConstraints { maker in
            maker.top.equalTo(tabsView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        tabsView.reload(filters: viewModel.tabs.map {
            FilterHeaderView.ViewItem.item(title: $0.title)
        })

        tabsView.onSelect = { [weak self] index in
            self?.onSelectTab(index: index)
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "search_discovery_24"), style: .plain, target: self, action: #selector(onTapDiscovery))

        postViewController.parentNavigationController = navigationController
        watchlistViewController.parentNavigationController = navigationController

        subscribe(disposeBag, viewModel.currentTabDriver) { [weak self] in self?.sync(currentTab: $0) }
    }

    private func sync(currentTab: MarketModule.Tab) {
        tabsView.select(index: currentTab.rawValue)
        setViewPager(tab: currentTab)
    }

    private func onSelectTab(index: Int) {
        guard let tab = MarketModule.Tab(rawValue: index) else {
            return
        }

        viewModel.onSelect(tab: tab)
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

    @objc private func onTapDiscovery() {
        navigationController?.pushViewController(MarketDiscoveryModule.viewController(), animated: true)
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

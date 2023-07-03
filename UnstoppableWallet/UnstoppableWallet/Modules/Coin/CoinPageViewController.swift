import Foundation
import UIKit
import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import HUD
import ComponentKit

class CoinPageViewController: ThemeViewController {
    private let viewModel: CoinPageViewModel
    private let disposeBag = DisposeBag()

    private let tabsView = FilterView(buttonStyle: .tab)
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

    private let overviewController: CoinOverviewViewController
    private let marketsController: CoinMarketsViewController
    private let analyticsController: CoinAnalyticsViewController
//    private let tweetsController: CoinTweetsViewController

    private var favorite = false

    init(viewModel: CoinPageViewModel, overviewController: CoinOverviewViewController, analyticsController: CoinAnalyticsViewController, marketsController: CoinMarketsViewController) {
        self.viewModel = viewModel
        self.overviewController = overviewController
        self.analyticsController = analyticsController
        self.marketsController = marketsController
//        self.tweetsController = tweetsController

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(UIView()) // prevent Large Title from Collapsing

        title = viewModel.title
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapCloseButton))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        view.addSubview(tabsView)
        tabsView.snp.makeConstraints { maker in
            maker.top.equalTo(view.safeAreaLayoutGuide)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(FilterView.height)
        }

        view.addSubview(pageViewController.view)
        pageViewController.view.snp.makeConstraints { maker in
            maker.top.equalTo(tabsView.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        tabsView.reload(filters: CoinPageModule.Tab.allCases.map {
            FilterView.ViewItem.item(title: $0.title)
        })

        tabsView.onSelect = { [weak self] index in
            self?.onSelectTab(index: index)
        }

        overviewController.parentNavigationController = navigationController
        analyticsController.parentNavigationController = navigationController
//        tweetsController.parentNavigationController = navigationController

        subscribe(disposeBag, viewModel.favoriteDriver) { [weak self] in
            self?.favorite = $0
            self?.syncButtons()
        }
        subscribe(disposeBag, viewModel.hudSignal) {
            HudHelper.instance.show(banner: $0)
        }

        onSelectTab(index: 0)
    }

    @objc private func onTapCloseButton() {
        dismiss(animated: true)
    }

    @objc private func onTapFavorite() {
        viewModel.onTapFavorite()
    }

    private func onSelectTab(index: Int) {
        guard let tab = CoinPageModule.Tab(rawValue: index) else {
            return
        }

        tabsView.select(index: tab.rawValue)
        setViewPager(tab: tab)
    }

    private func setViewPager(tab: CoinPageModule.Tab) {
        pageViewController.setViewControllers([viewController(tab: tab)], direction: .forward, animated: false)
    }

    private func viewController(tab: CoinPageModule.Tab) -> UIViewController {
        switch tab {
        case .overview: return overviewController
        case .analytics: return analyticsController
        case .markets: return marketsController
//        case .tweets: return tweetsController
        }
    }

    private func syncButtons() {
        var items = [UIBarButtonItem]()

        let favoriteItem = UIBarButtonItem(
                image: favorite ? UIImage(named: "filled_star_24") : UIImage(named: "star_24"),
                style: .plain,
                target: self,
                action: #selector(onTapFavorite)
        )
        favoriteItem.tintColor = favorite ? .themeJacob : .themeGray
        items.append(favoriteItem)

        navigationItem.rightBarButtonItems = items
    }

}

import UIKit
import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import HUD
import ComponentKit

class NftAssetViewController: ThemeViewController {
    private let tabsView = FilterHeaderView(buttonStyle: .tab)
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

    private let overviewController: NftAssetOverviewViewController
    private let activityController: NftActivityViewController

    init(overviewController: NftAssetOverviewViewController, activityController: NftActivityViewController) {
        self.overviewController = overviewController
        self.activityController = activityController

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        view.addSubview(tabsView)
        tabsView.snp.makeConstraints { maker in
            maker.top.equalTo(view.safeAreaLayoutGuide)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(FilterHeaderView.height)
        }

        view.addSubview(pageViewController.view)
        pageViewController.view.snp.makeConstraints { maker in
            maker.top.equalTo(tabsView.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        tabsView.reload(filters: NftAssetModule.Tab.allCases.map {
            FilterHeaderView.ViewItem.item(title: $0.title)
        })

        tabsView.onSelect = { [weak self] index in
            self?.onSelectTab(index: index)
        }

        overviewController.parentNavigationController = navigationController
        activityController.parentNavigationController = navigationController

        onSelectTab(index: 0)
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    private func onSelectTab(index: Int) {
        guard let tab = NftAssetModule.Tab(rawValue: index) else {
            return
        }

        tabsView.select(index: tab.rawValue)
        setViewPager(tab: tab)
    }

    private func setViewPager(tab: NftAssetModule.Tab) {
        pageViewController.setViewControllers([viewController(tab: tab)], direction: .forward, animated: false)
    }

    private func viewController(tab: NftAssetModule.Tab) -> UIViewController {
        switch tab {
        case .overview: return overviewController
        case .activity: return activityController
        }
    }

}

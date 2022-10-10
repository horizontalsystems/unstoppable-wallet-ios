import Foundation
import UIKit
import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import HUD
import ComponentKit

class NftCollectionViewController: ThemeViewController {
    private let viewModel: NftCollectionViewModel
    private let disposeBag = DisposeBag()

    private let tabsView = FilterHeaderView(buttonStyle: .tab)
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

    private let overviewController: NftCollectionOverviewViewController
    private let assetsController: NftCollectionAssetsViewController
    private let activityController: NftActivityViewController

    init(viewModel: NftCollectionViewModel, overviewController: NftCollectionOverviewViewController, assetsController: NftCollectionAssetsViewController, activityController: NftActivityViewController) {
        self.viewModel = viewModel
        self.overviewController = overviewController
        self.assetsController = assetsController
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

        tabsView.reload(filters: NftCollectionModule.Tab.allCases.map {
            FilterHeaderView.ViewItem.item(title: $0.title)
        })

        tabsView.onSelect = { [weak self] index in
            self?.onSelectTab(index: index)
        }

        overviewController.parentNavigationController = navigationController
        assetsController.parentNavigationController = navigationController
        activityController.parentNavigationController = navigationController

        onSelectTab(index: 0)
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    private func onSelectTab(index: Int) {
        guard let tab = NftCollectionModule.Tab(rawValue: index) else {
            return
        }

        tabsView.select(index: tab.rawValue)
        setViewPager(tab: tab)
    }

    private func setViewPager(tab: NftCollectionModule.Tab) {
        pageViewController.setViewControllers([viewController(tab: tab)], direction: .forward, animated: false)
    }

    private func viewController(tab: NftCollectionModule.Tab) -> UIViewController {
        switch tab {
        case .overview: return overviewController
        case .assets: return assetsController
        case .activity: return activityController
        }
    }

}

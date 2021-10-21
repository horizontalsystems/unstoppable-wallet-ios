import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import HUD
import ComponentKit

class CoinPageViewController: ThemeViewController {
    private let viewModel: CoinPageViewModel
    private let disposeBag = DisposeBag()

    private let subtitleCell = A7Cell()
    private let tabsView = FilterHeaderView(buttonStyle: .tab)
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

    private let overviewController: CoinOverviewViewController
    private let marketsController: CoinMarketsViewController
    private let detailsController: CoinOverviewViewController
    private let tweetsController: CoinOverviewViewController

    init(viewModel: CoinPageViewModel, overviewController: CoinOverviewViewController, marketsController: CoinMarketsViewController, detailsController: CoinOverviewViewController, tweetsController: CoinOverviewViewController) {
        self.viewModel = viewModel
        self.overviewController = overviewController
        self.marketsController = marketsController
        self.detailsController = detailsController
        self.tweetsController = tweetsController

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(UIView()) // prevent Large Title from Collapsing

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapCloseButton))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "rate_24")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(onTapFavorite))

        let viewItem = viewModel.viewItem
        title = viewItem.title

        view.addSubview(subtitleCell.contentView)
        subtitleCell.contentView.snp.makeConstraints { maker in
            maker.top.equalTo(view.safeAreaLayoutGuide)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightCell48)
        }
        subtitleCell.set(backgroundStyle: .transparent, isFirst: true)
        subtitleCell.titleColor = .themeGray
        subtitleCell.set(titleImageSize: .iconSize24)
        subtitleCell.valueColor = .themeGray
        subtitleCell.selectionStyle = .none

        subtitleCell.title = viewItem.subtitle
        subtitleCell.value = viewItem.marketCapRank
        subtitleCell.setTitleImage(urlString: viewItem.imageUrl, placeholder: UIImage(named: viewItem.imagePlaceholderName))

        view.addSubview(tabsView)
        tabsView.snp.makeConstraints { maker in
            maker.top.equalTo(subtitleCell.contentView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(FilterHeaderView.height)
        }

        view.addSubview(pageViewController.view)
        pageViewController.view.snp.makeConstraints { maker in
            maker.top.equalTo(tabsView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        tabsView.reload(filters: CoinPageModule.Tab.allCases.map {
            FilterHeaderView.ViewItem.item(title: $0.title)
        })

        tabsView.onSelect = { [weak self] index in
            self?.onSelectTab(index: index)
        }

        overviewController.parentNavigationController = navigationController
        detailsController.parentNavigationController = navigationController
        tweetsController.parentNavigationController = navigationController

        subscribe(disposeBag, viewModel.favoriteDriver) { [weak self] in self?.sync(favorite: $0) }
        subscribe(disposeBag, viewModel.favoriteHudSignal) { [weak self] in self?.showHud(title: $0) }

        onSelectTab(index: 0)
    }

    @objc private func onTapCloseButton() {
        dismiss(animated: true)
    }

    @objc private func onTapFavorite() {
        viewModel.toggleFavorite()
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
        case .markets: return marketsController
        case .details: return detailsController
        case .tweets: return tweetsController
        }
    }

    private func sync(favorite: Bool) {
        navigationItem.rightBarButtonItem?.tintColor = favorite ? UIColor.themeJacob : UIColor.themeGray
    }

    private func showHud(title: String) {
        HudHelper.instance.showSuccess(title: title)
    }

}

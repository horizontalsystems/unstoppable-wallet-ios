import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import HUD
import ComponentKit

class CoinPageViewController: ThemeViewController {
    private let viewModel: CoinPageViewModel
    private let favoriteViewModel: CoinFavoriteViewModel
//    private let priceAlertViewModel: CoinPriceAlertViewModel
    private let disposeBag = DisposeBag()

    private var favoriteButtonItem: UIBarButtonItem?
    private var alertButtonItem: UIBarButtonItem?

    private let subtitleCell = A7Cell()
    private let tabsView = FilterHeaderView(buttonStyle: .tab)
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

    private let overviewController: CoinOverviewViewController
    private let marketsController: CoinMarketsViewController
    private let detailsController: CoinOverviewViewController
    private let tweetsController: CoinOverviewViewController

    init(viewModel: CoinPageViewModel, favoriteViewModel: CoinFavoriteViewModel,
         overviewController: CoinOverviewViewController, marketsController: CoinMarketsViewController,
         detailsController: CoinOverviewViewController, tweetsController: CoinOverviewViewController) {
        self.viewModel = viewModel
        self.favoriteViewModel = favoriteViewModel
//        self.priceAlertViewModel = priceAlertViewModel
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

        tabsView.reload(filters: viewModel.tabs.map {
            FilterHeaderView.ViewItem.item(title: $0.title)
        })

        tabsView.onSelect = { [weak self] index in
            self?.onSelectTab(index: index)
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapCloseButton))

        overviewController.parentNavigationController = navigationController
        detailsController.parentNavigationController = navigationController
        tweetsController.parentNavigationController = navigationController

        subscribeViewModels()
        onSelectTab(index: 0)
    }

    @objc private func onTapCloseButton() {
        dismiss(animated: true)
    }

    private func subscribeViewModels() {
        // barItems section
//        subscribe(disposeBag, priceAlertViewModel.priceAlertActiveDriver) { [weak self] in self?.sync(priceAlertEnabled: $0) }
        subscribe(disposeBag, favoriteViewModel.favoriteDriver) { [weak self] in self?.sync(favorite: $0) }
        subscribe(disposeBag, favoriteViewModel.favoriteHudSignal) { [weak self] in self?.showHud(title: $0) }
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

    private func syncBarButtons() {
        navigationItem.rightBarButtonItems = [favoriteButtonItem, alertButtonItem].compactMap { $0 }
    }

    @objc private func onAlertTap() {
//        guard let chartNotificationViewController = ChartNotificationRouter.module(
//                coinType: priceAlertViewModel.coinType,
//                coinTitle: viewModel.coinTitle,
//                mode: .all) else {
//
//            return
//        }
//
//        present(chartNotificationViewController, animated: true)
    }

    @objc private func onFavoriteTap() {
        favoriteViewModel.favorite()
    }

    @objc private func onUnfavoriteTap() {
        favoriteViewModel.unfavorite()
    }

}

extension CoinPageViewController {

    // BarItems section

    private func sync(priceAlertEnabled: Bool) {
//        guard priceAlertViewModel.alertNotificationEnabled == true else {
//            alertButtonItem = nil
//            syncBarButtons()
//
//            return
//        }
//
//        var image: UIImage?
//        var imageTintColor: UIColor?
//        if priceAlertEnabled {
//            image = UIImage(named: "bell_ring_24")?.withRenderingMode(.alwaysTemplate)
//            imageTintColor = .themeJacob
//        } else {
//            image = UIImage(named: "bell_24")?.withRenderingMode(.alwaysTemplate)
//            imageTintColor = .themeGray
//        }
//
//        alertButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(onAlertTap))
//        alertButtonItem?.tintColor = imageTintColor
//
        syncBarButtons()
    }

    private func sync(favorite: Bool) {
        let selector = favorite ? #selector(onUnfavoriteTap) : #selector(onFavoriteTap)
        let color = favorite ? UIColor.themeJacob : UIColor.themeGray

        let favoriteImage = UIImage(named: "rate_24")?.withRenderingMode(.alwaysTemplate)
        favoriteButtonItem = UIBarButtonItem(image: favoriteImage, style: .plain, target: self, action: selector)
        favoriteButtonItem?.tintColor = color

        syncBarButtons()
    }

    private func showHud(title: String) {
        HudHelper.instance.showSuccess(title: title)
    }

}

import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import HUD
import ComponentKit

class CoinPageViewController: ThemeViewController {
    private let viewModel: CoinPageViewModel
    private let enableCoinView: EnableCoinView
    private let disposeBag = DisposeBag()

    private let subtitleCell = A7Cell()
    private let tabsView = FilterHeaderView(buttonStyle: .tab)
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

    private let overviewController: CoinOverviewViewController
    private let marketsController: CoinMarketsViewController
    private let detailsController: CoinDetailsViewController
    private let tweetsController: CoinOverviewViewController

    private var addWalletState: CoinPageViewModel.AddWalletState = .hidden
    private var favorite = false

    init(viewModel: CoinPageViewModel, enableCoinView: EnableCoinView, overviewController: CoinOverviewViewController, marketsController: CoinMarketsViewController, detailsController: CoinDetailsViewController, tweetsController: CoinOverviewViewController) {
        self.viewModel = viewModel
        self.enableCoinView = enableCoinView
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

        enableCoinView.onOpenController = { [weak self] controller in
            self?.present(controller, animated: true)
        }

        overviewController.parentNavigationController = navigationController
        detailsController.parentNavigationController = navigationController
        tweetsController.parentNavigationController = navigationController

        subscribe(disposeBag, viewModel.favoriteDriver) { [weak self] in
            self?.favorite = $0
            self?.syncButtons()
        }
        subscribe(disposeBag, viewModel.addWalletStateDriver) { [weak self] in
            self?.addWalletState = $0
            self?.syncButtons()
        }
        subscribe(disposeBag, viewModel.successHudSignal) {
            HudHelper.instance.showSuccess(title: $0)
        }
        subscribe(disposeBag, viewModel.attentionHudSignal) {
            HudHelper.instance.showAttention(title: $0)
        }

        onSelectTab(index: 0)
    }

    @objc private func onTapCloseButton() {
        dismiss(animated: true)
    }

    @objc private func onTapFavorite() {
        viewModel.onTapFavorite()
    }

    @objc private func onTapAddWallet() {
        viewModel.onTapAddWallet()
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

        if case .visible(let added) = addWalletState {
            let addWalletItem = UIBarButtonItem(
                    image: added ? UIImage(named: "in_wallet_24")?.withRenderingMode(.alwaysOriginal) : UIImage(named: "add_to_wallet_2_24"),
                    style: .plain,
                    target: self,
                    action: #selector(onTapAddWallet)
            )
            addWalletItem.tintColor = added ? nil : .themeGray
            items.append(addWalletItem)
        }

        navigationItem.rightBarButtonItems = items
    }

}

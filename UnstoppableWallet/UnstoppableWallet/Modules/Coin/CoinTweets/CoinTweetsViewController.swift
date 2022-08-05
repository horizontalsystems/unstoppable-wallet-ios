import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import ComponentKit
import HUD

class CoinTweetsViewController: ThemeViewController {
    private let viewModel: CoinTweetsViewModel
    private let urlManager: UrlManager
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let infoView = PlaceholderView()
    private let errorView = PlaceholderViewModule.reachabilityView()
    private let refreshControl = UIRefreshControl()

    weak var parentNavigationController: UINavigationController?

    private var viewItems: [CoinTweetsViewModel.ViewItem]?

    init(viewModel: CoinTweetsViewModel, urlManager: UrlManager) {
        self.viewModel = viewModel
        self.urlManager = urlManager

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

        let wrapperView = UIView()

        view.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        wrapperView.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.startAnimating()

        wrapperView.addSubview(infoView)
        infoView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        infoView.image = UIImage(named: "no_tweets_48")

        wrapperView.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        errorView.configureSyncError(action: { [weak self] in self?.onRetry() })

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: TweetCell.self)
        tableView.registerCell(forClass: SecondaryButtonCell.self)

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, viewModel.infoDriver) { [weak self] info in
            if let info = info {
                self?.infoView.text = info
                self?.infoView.isHidden = false
            } else {
                self?.infoView.isHidden = true
            }
        }
        subscribe(disposeBag, viewModel.syncErrorDriver) { [weak self] visible in
            self?.errorView.isHidden = !visible
        }
        viewModel.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.refreshControl = refreshControl
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
        viewModel.refresh()
    }

    private func sync(viewItems: [CoinTweetsViewModel.ViewItem]?) {
        self.viewItems = viewItems

        if viewItems != nil {
            tableView.isHidden = false
        } else {
            tableView.isHidden = true
        }

        tableView.reload()
    }

    private func open(username: String, tweetId: String) {
        if let appUrl = URL(string: "twitter://status?id=\(tweetId)"), UIApplication.shared.canOpenURL(appUrl) {
            UIApplication.shared.open(appUrl)
            return
        }

        let webUrl = "https://twitter.com/\(username)/status/\(tweetId)"
        urlManager.open(url: webUrl, from: parentNavigationController)
    }

    private func onTapSeeOnTwitter() {
        guard let username = viewModel.username else {
            return
        }

        if let appUrl = URL(string: "twitter://user?screen_name=\(username)"), UIApplication.shared.canOpenURL(appUrl) {
            UIApplication.shared.open(appUrl)
            return
        }

        let webUrl = "https://twitter.com/\(username)"
        urlManager.open(url: webUrl, from: parentNavigationController)
    }

}

extension CoinTweetsViewController: SectionsDataSource {

    private func row(viewItem: CoinTweetsViewModel.ViewItem) -> RowProtocol {
        Row<TweetCell>(
                id: viewItem.id,
                autoDeselect: true,
                dynamicHeight: { containerWidth in TweetCell.height(viewItem: viewItem, containerWidth: containerWidth) },
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                    cell.bind(viewItem: viewItem)
                },
                action: { [weak self] _ in
                    self?.open(username: viewItem.username, tweetId: viewItem.id)
                }
        )
    }

    private func buttonSection() -> SectionProtocol {
        Section(
                id: "button_section",
                headerState: .margin(height: .margin16),
                footerState: .margin(height: .margin16),
                rows: [
                    Row<SecondaryButtonCell>(
                            id: "see-on-twitter",
                            height: SecondaryButtonCell.height,
                            bind: { [weak self] cell, _ in
                                cell.set(style: .default)
                                cell.title = "coin_page.tweets.see_on_twitter".localized
                                cell.onTap = {
                                    self?.onTapSeeOnTwitter()
                                }
                            }
                    )
                ]
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let viewItems = viewItems {
            for (index, viewItem) in viewItems.enumerated() {
                let section = Section(
                        id: "tweet_\(index)",
                        headerState: .margin(height: .margin12),
                        rows: [row(viewItem: viewItem)]
                )

                sections.append(section)
            }

            sections.append(buttonSection())
        }

        return sections
    }

}

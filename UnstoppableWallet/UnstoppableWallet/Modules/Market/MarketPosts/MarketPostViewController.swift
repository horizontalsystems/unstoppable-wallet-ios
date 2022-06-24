import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import ComponentKit
import HUD

class MarketPostViewController: ThemeViewController {
    private let viewModel: MarketPostViewModel
    private let urlManager: UrlManager
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()
    private let refreshControl = UIRefreshControl()

    weak var parentNavigationController: UINavigationController?

    private var viewItems: [MarketPostViewModel.ViewItem]?

    init(viewModel: MarketPostViewModel, urlManager: UrlManager) {
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

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: PostCell.self)

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

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, viewModel.syncErrorDriver) { [weak self] visible in
            self?.errorView.isHidden = !visible
        }

        viewModel.onLoad()
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

    private func sync(viewItems: [MarketPostViewModel.ViewItem]?) {
        self.viewItems = viewItems

        if viewItems != nil {
            tableView.bounces = true
        } else {
            tableView.bounces = false
        }

        tableView.reload()
    }

    private func open(url: String) {
        urlManager.open(url: url, from: parentNavigationController)
    }

}

extension MarketPostViewController: SectionsDataSource {

    private func row(viewItem: MarketPostViewModel.ViewItem) -> RowProtocol {
        Row<PostCell>(
                id: viewItem.title,
                height: PostCell.height,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                    cell.bind(
                            header: viewItem.source,
                            title: viewItem.title,
                            body: viewItem.body,
                            time: viewItem.timeAgo
                    )
                },
                action: { [weak self] _ in
                    self?.open(url: viewItem.url)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let viewItems = viewItems {
            for (index, viewItem) in viewItems.enumerated() {
                let section = Section(
                        id: "post_\(index)",
                        headerState: .margin(height: .margin12),
                        footerState: .margin(height: index == viewItems.count - 1 ? .margin32 : 0),
                        rows: [row(viewItem: viewItem)]
                )

                sections.append(section)
            }
        }

        return sections
    }

}

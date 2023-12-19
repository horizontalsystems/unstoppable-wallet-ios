import Chart
import ComponentKit
import HUD
import RxCocoa
import RxSwift
import SectionsTableView
import ThemeKit
import UIKit

protocol IMarketOverviewDataSource {
    var isReady: Bool { get }
    var updateObservable: Observable<Void> { get }
    func sections(tableView: SectionsTableView) -> [SectionProtocol]
}

class MarketOverviewViewController: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let viewModel: MarketOverviewViewModel
    private let dataSources: [IMarketOverviewDataSource]

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()
    private let refreshControl = UIRefreshControl()

    init(viewModel: MarketOverviewViewModel, dataSources: [IMarketOverviewDataSource]) {
        self.viewModel = viewModel
        self.dataSources = dataSources

        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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
        tableView.showsVerticalScrollIndicator = false

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: MarketOverviewHeaderCell.self)

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

        subscribe(disposeBag, viewModel.successDriver) { [weak self] in self?.sync(success: $0) }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, viewModel.syncErrorDriver) { [weak self] visible in
            self?.errorView.isHidden = !visible
        }

        for dataSource in dataSources {
            subscribe(MainScheduler.instance, disposeBag, dataSource.updateObservable) { [weak self] in self?.handleDataSourceUpdate() }
        }

        viewModel.onLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.refreshControl = refreshControl
    }

    @objc private func onRetry() {
        viewModel.refresh()
    }

    @objc func onRefresh() {
        viewModel.refresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    private func sync(success: Bool) {
        if success {
            tableView.isHidden = false
        } else {
            tableView.isHidden = true
        }
    }

    func handleDataSourceUpdate() {
        guard dataSources.allSatisfy(\.isReady) else {
            return
        }

        tableView.reload()
    }
}

extension MarketOverviewViewController: SectionsDataSource {
    func buildSections() -> [SectionProtocol] {
        dataSources.compactMap { $0.sections(tableView: tableView) }.flatMap { $0 }
    }
}

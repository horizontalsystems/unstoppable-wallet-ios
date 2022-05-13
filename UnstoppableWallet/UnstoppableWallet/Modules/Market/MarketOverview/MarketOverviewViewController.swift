import UIKit
import RxSwift
import RxCocoa
import ThemeKit
import SectionsTableView
import ComponentKit
import HUD
import Chart

protocol IMarketOverviewDataSource {
    var presentDelegate: IPresentDelegate { get set }

    func sections(tableView: UITableView) -> [SectionProtocol]
}

class MarketOverviewViewController: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let viewModel: MarketOverviewViewModel
    private let dataSources: [IMarketOverviewDataSource]

    let tableView = SectionsTableView(style: .grouped)
    private var sections = [SectionProtocol]()
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderView()
    private let refreshControl = UIRefreshControl()

    init(viewModel: MarketOverviewViewModel, dataSources: [IMarketOverviewDataSource]) {
        self.viewModel = viewModel
        self.dataSources = dataSources

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
        tableView.registerCell(forClass: MarketOverviewHeaderCell.self)
        tableView.registerCell(forClass: G14Cell.self)
        tableView.registerCell(forClass: B1Cell.self)

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.startAnimating()

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        errorView.configureSyncError(target: self, action: #selector(onRetry))

        subscribe(disposeBag, viewModel.successDriver) { [weak self] in
            self?.sync()
        }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, viewModel.syncErrorDriver) { [weak self] visible in
            self?.tableView.bounces = !visible
            self?.errorView.isHidden = !visible
        }
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

    func sync() {
        sections = dataSources.compactMap { $0.sections(tableView: tableView) }.flatMap { $0 }
        tableView.reload()
    }

}

extension MarketOverviewViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        sections
    }

}

import UIKit
import RxSwift
import RxCocoa
import ThemeKit
import SectionsTableView
import ComponentKit
import HUD
import Chart

protocol IMarketOverviewDataSource {
    var parentNavigationController: UINavigationController? { get set }
    var status: DataStatus<[SectionProtocol]> { get }
    var updateDriver: Driver<()> { get }

    func refresh()
}

class MarketOverviewViewController: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let dataSources: [IMarketOverviewDataSource]

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderView()
    private let refreshControl = UIRefreshControl()

    weak var parentNavigationController: UINavigationController? {
        didSet {
            dataSources.forEach {
                var dataSource = $0
                dataSource.parentNavigationController = parentNavigationController
            }
        }
    }

    init(dataSources: [IMarketOverviewDataSource]) {
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

        dataSources.forEach { dataSource in
            subscribe(disposeBag, dataSource.updateDriver) { [weak self] in
                self?.sync()
            }
        }
        sync()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.refreshControl = refreshControl
    }

    private var isLoading: Bool {
        dataSources.first { $0.status.isLoading } != nil
    }

    private var error: String? {
        dataSources
                .first { $0.status.error != nil }?
                .status
                .error?
                .smartDescription
    }

    private var sections: [SectionProtocol] {
        var sections = [SectionProtocol]()
        dataSources.forEach { source in
            sections.append(contentsOf: source.status.data ?? [])
        }
        return sections
    }

    private func sync() {
        syncLoading()
        syncError()

        tableView.reload()
    }

    private func syncError() {
        if let error = error {
            errorView.isHidden = false
        } else {
            errorView.isHidden = true
        }
    }

    private func syncLoading() {
        spinner.isHidden = !isLoading
    }

    @objc private func onRetry() {
        refresh()
    }

    @objc func onRefresh() {
        refresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    private func refresh() {
        dataSources.forEach { $0.refresh() }
    }

}

extension MarketOverviewViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        tableView.bounces = error == nil && !sections.isEmpty
        return error == nil ? sections : []
    }

}

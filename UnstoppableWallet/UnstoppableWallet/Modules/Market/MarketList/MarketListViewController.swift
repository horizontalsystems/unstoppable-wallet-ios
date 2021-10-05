import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import ComponentKit
import HUD

class MarketListViewController: ThemeViewController {
    private let listViewModel: MarketListViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .plain)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = MarketListErrorView()
    private let refreshControl = UIRefreshControl()

    private var viewItems = [MarketListViewModel.ViewItem]()

    var viewController: UIViewController? { self }
    var headerView: UITableViewHeaderFooterView? { nil }
    var emptyView: UIView? { nil }
    var topSections: [SectionProtocol] { [] }

    init(listViewModel: MarketListViewModel) {
        self.listViewModel = listViewModel

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
        tableView.registerCell(forClass: G14Cell.self)

        if let emptyView = emptyView {
            view.addSubview(emptyView)
            emptyView.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview().inset(CGFloat.margin48)
                maker.centerY.equalToSuperview()
            }
        }

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.startAnimating()

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        errorView.onTapRetry = { [weak self] in self?.refresh() }

        subscribe(disposeBag, listViewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, listViewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, listViewModel.errorDriver) { [weak self] error in
            if let error = error {
                self?.errorView.text = error
                self?.errorView.isHidden = false
            } else {
                self?.errorView.isHidden = true
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.refreshControl = refreshControl
    }

    func refresh() {
        listViewModel.refresh()
    }

    @objc private func onRefresh() {
        refresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    private func sync(viewItems: [MarketListViewModel.ViewItem]?) {
        if let viewItems = viewItems {
            self.viewItems = viewItems
            emptyView?.isHidden = !viewItems.isEmpty
        } else {
            self.viewItems = []
            emptyView?.isHidden = true
        }

        tableView.bounces = !self.viewItems.isEmpty
        tableView.reload()
    }

    private func onSelect(viewItem: MarketListViewModel.ViewItem) {
        guard let module = CoinPageModule.viewController(coinUid: viewItem.uid) else {
            return
        }

        viewController?.present(module, animated: true)
    }

}

extension MarketListViewController: SectionsDataSource {

    private func bind(cell: G14Cell, viewItem: MarketListViewModel.ViewItem) {
        cell.setTitleImage(urlString: viewItem.iconUrl, placeholder: UIImage(named: "icon_placeholder_24"))
        cell.topText = viewItem.name
        cell.bottomText = viewItem.code
        cell.leftBadgeText = viewItem.rank

        cell.primaryValueText = viewItem.price

        let marketFieldData = marketFieldPreference(dataValue: viewItem.dataValue)
        cell.secondaryTitleText = marketFieldData.title
        cell.secondaryValueText = marketFieldData.value
        cell.secondaryValueTextColor = marketFieldData.color
    }

    private func marketFieldPreference(dataValue: MarketListViewModel.DataValue) -> (title: String?, value: String?, color: UIColor) {
        let title: String?
        let value: String?
        let color: UIColor

        switch dataValue {
        case .diff(let diff):
            title = nil
            value = diff.flatMap { ValueFormatter.instance.format(percentValue: $0) } ?? "----"
            if let diff = diff {
                color = diff.isSignMinus ? .themeLucian : .themeRemus
            } else {
                color = .themeGray50
            }
        case .volume(let volume):
            title = "market.top.volume.title".localized
            value = volume
            color = .themeGray
        case .marketCap(let marketCap):
            title = "market.top.market_cap.title".localized
            value = marketCap
            color = .themeGray
        }

        return (title: title, value: value, color: color)
    }

    private func row(viewItem: MarketListViewModel.ViewItem, isLast: Bool) -> RowProtocol {
        Row<G14Cell>(
                id: viewItem.uid,
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { [weak self] cell, _ in
                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                    self?.bind(cell: cell, viewItem: viewItem)
                },
                action: { [weak self] _ in
                    self?.onSelect(viewItem: viewItem)
                })
    }

    func buildSections() -> [SectionProtocol] {
        let headerState: ViewState<UITableViewHeaderFooterView>

        if let headerView = headerView, !viewItems.isEmpty {
            headerState = .static(view: headerView, height: .heightSingleLineCell)
        } else {
            headerState = .margin(height: 0)
        }

        return [
            Section(
                    id: "coins",
                    headerState: headerState,
                    rows: viewItems.enumerated().map { row(viewItem: $1, isLast: $0 == viewItems.count - 1) }
            )
        ]
    }

}

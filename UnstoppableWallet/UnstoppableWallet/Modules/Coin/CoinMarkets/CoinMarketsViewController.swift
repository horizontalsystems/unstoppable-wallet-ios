import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import ComponentKit
import HUD

class CoinMarketsViewController: ThemeViewController {
    private let viewModel: CoinMarketsViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .plain)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let infoView = PlaceholderView()
    private let errorView = PlaceholderView()
    private let headerView: MarketSingleSortHeaderView

    private var viewItems: [CoinMarketsViewModel.ViewItem]?

    init(viewModel: CoinMarketsViewModel, headerViewModel: MarketSingleSortHeaderViewModel) {
        self.viewModel = viewModel
        headerView = MarketSingleSortHeaderView(viewModel: headerViewModel, hasTopSeparator: false)

        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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

        wrapperView.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        errorView.configureSyncError(target: self, action: #selector(onRetry))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: G14Cell.self)

        wrapperView.addSubview(infoView)
        infoView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        infoView.image = UIImage(named: "no_data_48")

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
        subscribe(disposeBag, viewModel.scrollToTopSignal) { [weak self] in self?.scrollToTop() }

        viewModel.onLoad()
    }

    @objc private func onRetry() {
        viewModel.onTapRetry()
    }

    private func sync(viewItems: [CoinMarketsViewModel.ViewItem]?) {
        self.viewItems = viewItems

        if let viewItems = viewItems, !viewItems.isEmpty {
            tableView.isHidden = false
        } else {
            tableView.isHidden = true
        }

        tableView.reload()
    }

    private func scrollToTop() {
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
    }

}

extension CoinMarketsViewController: SectionsDataSource {

    private func row(viewItem: CoinMarketsViewModel.ViewItem, index: Int, isLast: Bool) -> RowProtocol {
        Row<G14Cell>(
                id: "row-\(index)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                    cell.setTitleImage(urlString: viewItem.marketImageUrl, placeholder: nil)
                    cell.titleImageCornerRadius = .cornerRadius4
                    cell.titleImageBackgroundColor = .themeSteel10
                    cell.topText = viewItem.market
                    cell.bottomText = viewItem.pair
                    cell.primaryValueText = viewItem.rate
                    cell.secondaryTitleText = "market.market_field.vol".localized
                    cell.secondaryValueText = viewItem.volume
                    cell.selectionStyle = viewItem.tradeUrl == nil ? .none : .default
                },
                action: { _ in
                    if let appUrl = URL(string: viewItem.tradeUrl ?? ""), UIApplication.shared.canOpenURL(appUrl) {
                        UIApplication.shared.open(appUrl)
                    }
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        let headerState: ViewState<UITableViewHeaderFooterView>

        if let viewItems = viewItems, !viewItems.isEmpty {
            headerState = .static(view: headerView, height: .heightSingleLineCell)
        } else {
            headerState = .margin(height: 0)
        }

        return [
            Section(
                    id: "coins",
                    headerState: headerState,
                    footerState: .marginColor(height: .margin32, color: .clear) ,
                    rows: viewItems.map { viewItems in
                        viewItems.enumerated().map { row(viewItem: $1, index: $0, isLast: $0 == viewItems.count - 1) }
                    } ?? []
            )
        ]
    }

}

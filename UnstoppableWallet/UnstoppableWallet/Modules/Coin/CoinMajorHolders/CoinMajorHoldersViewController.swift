import ThemeKit
import SnapKit
import SectionsTableView
import ComponentKit
import RxSwift
import RxCocoa
import HUD

class CoinMajorHoldersViewController: ThemeViewController {
    private let viewModel: CoinMajorHoldersViewModel
    private let urlManager: UrlManager
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = MarketListErrorView()
    private var chartCell = CoinMajorHolderChartCell()

    private var stateViewItem: CoinMajorHoldersViewModel.StateViewItem?

    init(viewModel: CoinMajorHoldersViewModel, urlManager: UrlManager) {
        self.viewModel = viewModel
        self.urlManager = urlManager

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "coin_page.major_holders".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: BCell.self)
        tableView.registerCell(forClass: CoinMajorHolderCell.self)
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.startAnimating()

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        errorView.onTapRetry = { [weak self] in self?.viewModel.refresh() }

        subscribe(disposeBag, viewModel.stateViewItemDriver) { [weak self] in self?.sync(stateViewItem: $0) }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, viewModel.errorDriver) { [weak self] error in
            if let error = error {
                self?.errorView.text = error
                self?.errorView.isHidden = false
            } else {
                self?.errorView.isHidden = true
            }
        }
    }

    private func sync(stateViewItem: CoinMajorHoldersViewModel.StateViewItem?) {
        self.stateViewItem = stateViewItem

        if let stateViewItem = stateViewItem {
            tableView.bounces = true
            chartCell.set(chartPercents: stateViewItem.chartPercents, percent: stateViewItem.percent)
        } else {
            tableView.bounces = false
        }

        tableView.reload()
    }

    private func open(address: String) {
        urlManager.open(url: "https://etherscan.io/address/\(address)", from: self)
    }

}

extension CoinMajorHoldersViewController: SectionsDataSource {

    private var headerRow: RowProtocol {
        Row<BCell>(
                id: "header",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.selectionStyle = .none
                    cell.title = "coin_page.major_holders.top_ethereum_wallets".localized
                }
        )
    }

    private func row(viewItem: CoinMajorHoldersViewModel.ViewItem, isLast: Bool) -> RowProtocol {
        Row<CoinMajorHolderCell>(
                id: viewItem.order,
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                    cell.numberText = viewItem.order
                    cell.title = viewItem.percent
                    cell.set(address: viewItem.address)
                    cell.onTapIcon = { [weak self] in
                        self?.open(address: viewItem.address)
                    }
                }
        )
    }

    private func footer(text: String) -> ViewState<BottomDescriptionHeaderFooterView> {
        .cellType(
                hash: "bottom_description",
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { width in
                    BottomDescriptionHeaderFooterView.height(containerWidth: width, text: text)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        guard let stateViewItem = stateViewItem else {
            return []
        }

        return [
            Section(
                    id: "chart",
                    footerState: footer(text: "coin_page.major_holders.description".localized),
                    rows: [
                        StaticRow(
                                cell: chartCell,
                                id: "chart",
                                dynamicHeight: { width in
                                    CoinMajorHolderChartCell.height(containerWidth: width)
                                }
                        )
                    ]
            ),
            Section(
                    id: "holders",
                    footerState: .margin(height: .margin32),
                    rows: [headerRow] + stateViewItem.viewItems.enumerated().map { row(viewItem: $1, isLast: $0 == stateViewItem.viewItems.count - 1) }
            )
        ]
    }

}

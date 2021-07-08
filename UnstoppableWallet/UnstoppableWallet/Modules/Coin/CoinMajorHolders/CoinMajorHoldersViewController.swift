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
    private let errorView = ErrorView()
    private var chartCell = CoinMajorHolderChartCell()

    private var viewItems = [CoinMajorHoldersViewModel.ViewItem]()

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

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(CGFloat.margin16)
        }

        errorView.text = "coin_page.major_holders.sync_error".localized

        subscribe(disposeBag, viewModel.stateDriver) { [weak self] in self?.sync(state: $0) }
    }

    private func sync(state: CoinMajorHoldersViewModel.State) {
        tableView.isHidden = true
        spinner.isHidden = true
        errorView.isHidden = true

        switch state {
        case .loading:
            spinner.isHidden = false
            spinner.startAnimating()
        case .failed:
            errorView.isHidden = false
        case .loaded(let stateViewItem):
            chartCell.set(chartPercents: stateViewItem.chartPercents, percent: stateViewItem.percent)
            viewItems = stateViewItem.viewItems

            tableView.reload()
            tableView.isHidden = false
        }
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
                    cell.title = "coin_page.major_holders.top_wallets".localized
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
        [
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
                    rows: [headerRow] + viewItems.enumerated().map { row(viewItem: $1, isLast: $0 == viewItems.count - 1) }
            )
        ]
    }

}

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
    private let infoLabel = UILabel()
    private let errorView = MarketListErrorView()
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

        errorView.onTapRetry = { [weak self] in self?.viewModel.onRefresh() }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: G14Cell.self)

        wrapperView.addSubview(infoLabel)
        infoLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin48)
            maker.centerY.equalToSuperview()
        }

        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.font = .subhead2
        infoLabel.textColor = .themeGray

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, viewModel.infoDriver) { [weak self] info in
            if let info = info {
                self?.infoLabel.text = info
                self?.infoLabel.isHidden = false
            } else {
                self?.infoLabel.isHidden = true
            }
        }

        subscribe(disposeBag, viewModel.errorDriver) { [weak self] error in
            if let error = error {
                self?.errorView.text = error
                self?.errorView.isHidden = false
            } else {
                self?.errorView.isHidden = true
            }
        }
        subscribe(disposeBag, viewModel.scrollToTopSignal) { [weak self] in self?.scrollToTop() }

        viewModel.onLoad()
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

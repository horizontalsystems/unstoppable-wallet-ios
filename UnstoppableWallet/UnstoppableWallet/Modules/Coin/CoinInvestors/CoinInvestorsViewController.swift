import RxSwift
import RxCocoa
import SnapKit
import ThemeKit
import SectionsTableView
import ComponentKit
import HUD

class CoinInvestorsViewController: ThemeViewController {
    private let viewModel: CoinInvestorsViewModel
    private let urlManager: UrlManager
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = MarketListErrorView()

    private var viewItems: [CoinInvestorsViewModel.ViewItem]?

    init(viewModel: CoinInvestorsViewModel, urlManager: UrlManager) {
        self.viewModel = viewModel
        self.urlManager = urlManager

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "coin_page.funds_invested".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: A2Cell.self)
        tableView.registerCell(forClass: B7Cell.self)

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

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
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

    private func sync(viewItems: [CoinInvestorsViewModel.ViewItem]?) {
        self.viewItems = viewItems

        if viewItems != nil {
            tableView.bounces = true
        } else {
            tableView.bounces = false
        }

        tableView.reload()
    }

}

extension CoinInvestorsViewController: SectionsDataSource {

    private func headerSection(index: Int, title: String, value: String) -> SectionProtocol {
        Section(
                id: "header-\(index)",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin12),
                rows: [
                    Row<B7Cell>(
                            id: "header-\(index)",
                            height: .heightSingleLineCell,
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .transparent)
                                cell.title = title
                                cell.titleTextColor = .themeJacob
                                cell.value = value
                                cell.selectionStyle = .none
                            }
                    )
                ]
        )
    }

    private func row(fundViewItem: CoinInvestorsViewModel.FundViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        Row<A2Cell>(
                id: fundViewItem.url,
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                    cell.title = fundViewItem.name
                    cell.setTitleImage(urlString: fundViewItem.logoUrl, placeholder: UIImage(named: "icon_placeholder_24"))
                    cell.value = fundViewItem.isLead ? "coin_page.funds_invested.lead".localized : nil
                    cell.valueColor = .themeRemus
                },
                action: { [weak self] _ in
                    self?.urlManager.open(url: fundViewItem.url, from: self)
                }
        )
    }

    private func section(index: Int, fundViewItems: [CoinInvestorsViewModel.FundViewItem], isLast: Bool) -> SectionProtocol {
        Section(
                id: "section-\(index)",
                footerState: .margin(height: isLast ? .margin32 : 0),
                rows: fundViewItems.enumerated().map { index, fundViewItem in
                    row(fundViewItem: fundViewItem, isFirst: index == 0, isLast: index == fundViewItems.count - 1)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        guard let viewItems = viewItems else {
            return []
        }

        var sections = [SectionProtocol]()

        for (index, viewItem) in viewItems.enumerated() {
            sections.append(headerSection(index: index, title: viewItem.amount, value: viewItem.info))
            sections.append(section(index: index, fundViewItems: viewItem.fundViewItems, isLast: index == viewItems.count - 1))
        }

        return sections
    }

}

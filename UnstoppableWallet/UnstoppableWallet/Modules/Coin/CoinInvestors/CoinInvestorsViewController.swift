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
                    CellBuilder.row(
                            elements: [.text, .text],
                            tableView: tableView,
                            id: "header-\(index)",
                            height: .heightSingleLineCell,
                            bind: { cell in
                                cell.set(backgroundStyle: .transparent)

                                cell.bind(index: 0) { (component: TextComponent) in
                                    component.set(style: .b3)
                                    component.text = title
                                }

                                cell.bind(index: 1) { (component: TextComponent) in
                                    component.set(style: .d1)
                                    component.text = value
                                }
                            }
                    )
                ]
        )
    }

    private func bind(cell: BaseThemeCell, fundViewItem: CoinInvestorsViewModel.FundViewItem) {
        cell.bind(index: 0) { (component: ImageComponent) in
            component.setImage(urlString: fundViewItem.logoUrl, placeholder: UIImage(named: "icon_placeholder_24"))
        }

        cell.bind(index: 1) { (component: TextComponent) in
            component.set(style: .b2)
            component.text = fundViewItem.name
        }

        cell.bind(index: 2) { (component: TextComponent) in
            component.isHidden = !fundViewItem.isLead
            component.set(style: .c4)
            component.text = "coin_page.funds_invested.lead".localized
        }
    }

    private func row(fundViewItem: CoinInvestorsViewModel.FundViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        if fundViewItem.url.isEmpty {
            return CellBuilder.row(
                    elements: [.image24, .text, .text],
                    tableView: tableView,
                    id: fundViewItem.uid,
                    height: .heightCell48,
                    bind: { [weak self] cell in
                        cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                        self?.bind(cell: cell, fundViewItem: fundViewItem)
                    }
            )
        } else {
            return CellBuilder.selectableRow(
                    elements: [.image24, .text, .text, .margin8, .image20],
                    tableView: tableView,
                    id: fundViewItem.uid,
                    height: .heightCell48,
                    autoDeselect: true,
                    bind: { [weak self] cell in
                        cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                        self?.bind(cell: cell, fundViewItem: fundViewItem)

                        cell.bind(index: 3) { (component: ImageComponent) in
                            component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
                        }
                    },
                    action: { [weak self] in
                        self?.urlManager.open(url: fundViewItem.url, from: self)
                    }
            )
        }
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

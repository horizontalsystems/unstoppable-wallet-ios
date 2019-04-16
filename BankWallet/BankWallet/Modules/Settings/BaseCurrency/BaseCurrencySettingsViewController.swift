import UIKit
import SectionsTableView

class BaseCurrencySettingsViewController: WalletViewController, SectionsDataSource {
    private let delegate: IBaseCurrencySettingsViewDelegate

    private var items = [CurrencyItem]()

    let tableView = SectionsTableView(style: .grouped)

    init(delegate: IBaseCurrencySettingsViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        tableView.registerCell(forClass: DoubleLineCell.self)
        tableView.registerHeaderFooter(forClass: SectionSeparator.self)
        tableView.sectionDataSource = self
        tableView.separatorColor = .clear

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings_base_currency.title".localized

        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        let currenciesHeader: ViewState<SectionSeparator> = .cellType(hash: "currencies_header", binder: { view in
            view.bind(showTopSeparator: false)
        }, dynamicHeight: { _ in SettingsTheme.subSettingsHeaderHeight })
        let currenciesFooter: ViewState<SectionSeparator> = .cellType(hash: "currencies_header", binder: { view in
            view.bind(showBottomSeparator: false)
        }, dynamicHeight: { _ in SettingsTheme.subSettingsHeaderHeight })

        let itemsCount = items.count
        sections.append(Section(id: "currencies", headerState: currenciesHeader, footerState: currenciesFooter, rows: items.enumerated().map { (index, item) in
            Row<DoubleLineCell>(id: item.code, height: SettingsTheme.currencyCellHeight, bind: { cell, _ in
                cell.bind(title: item.code, subtitle: item.symbol, selected: item.selected, last: index == itemsCount - 1)
            }, action: { [weak self] _ in
                self?.delegate.didSelect(item: item)
            })
        }))

        return sections
    }

}

extension BaseCurrencySettingsViewController: IBaseCurrencySettingsView {

    func show(items: [CurrencyItem]) {
        self.items = items
        tableView.reload()
    }

}

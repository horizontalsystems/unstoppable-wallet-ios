import UIKit
import SectionsTableViewKit

class BaseCurrencySettingsViewController: UIViewController, SectionsDataSource {
    private let delegate: IBaseCurrencySettingsViewDelegate

    private var items = [CurrencyItem]()

    let tableView = SectionsTableView(style: .grouped)

    init(delegate: IBaseCurrencySettingsViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        tableView.registerCell(forClass: CurrencyCell.self)
        tableView.sectionDataSource = self
        tableView.separatorColor = SettingsTheme.cellSelectBackground

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

        view.backgroundColor = AppTheme.controllerBackground

        delegate.viewDidLoad()
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(Section(id: "currencies", headerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), footerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), rows: items.map { item in
            Row<CurrencyCell>(id: item.code, height: SettingsTheme.currencyCellHeight, bind: { cell, _ in
                cell.bind(title: item.code, subtitle: item.symbol, selected: item.selected)
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

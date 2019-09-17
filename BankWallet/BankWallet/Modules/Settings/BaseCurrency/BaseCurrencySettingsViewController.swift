import UIKit
import SectionsTableView

class BaseCurrencySettingsViewController: WalletViewController {
    private let delegate: IBaseCurrencySettingsViewDelegate

    private var items = [CurrencyViewItem]()
    private let tableView = SectionsTableView(style: .grouped)

    init(delegate: IBaseCurrencySettingsViewDelegate) {
        self.delegate = delegate

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings_base_currency.title".localized

        tableView.registerCell(forClass: DoubleLineCell.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()
        tableView.buildSections()
    }

}

extension BaseCurrencySettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        return [
            Section(
                    id: "currencies",
                    headerState: .margin(height: SettingsTheme.subSettingsHeaderHeight),
                    footerState: .margin(height: SettingsTheme.subSettingsHeaderHeight),
                    rows: items.enumerated().map { (index, item) in
                        Row<DoubleLineCell>(id: item.code, height: SettingsTheme.doubleLineCellHeight, bind: { [unowned self] cell, _ in
                            cell.bind(icon: UIImage(named: item.code), title: item.code, subtitle: item.symbol, selected: item.selected, last: index == self.items.count - 1)
                        }, action: { [weak self] _ in
                            self?.delegate.didSelect(index: index)
                        })
                    }
            )
        ]
    }

}

extension BaseCurrencySettingsViewController: IBaseCurrencySettingsView {

    func show(viewItems: [CurrencyViewItem]) {
        self.items = viewItems
    }

}

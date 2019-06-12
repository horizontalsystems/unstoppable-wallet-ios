import UIKit
import SectionsTableView

class LanguageSettingsViewController: WalletViewController, SectionsDataSource {
    private let delegate: ILanguageSettingsViewDelegate

    private var items = [LanguageItem]()

    let tableView = SectionsTableView(style: .grouped)

    init(delegate: ILanguageSettingsViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        tableView.registerCell(forClass: DoubleLineCell.self)
        tableView.registerHeaderFooter(forClass: SectionSeparator.self)
        tableView.sectionDataSource = self
        tableView.separatorColor = SettingsTheme.cellSelectBackground
        tableView.separatorColor = .clear

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()
        tableView.reload()
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        let languagesHeader: ViewState<SectionSeparator> = .cellType(hash: "currencies_header", binder: { view in
            view.bind(showTopSeparator: false)
        }, dynamicHeight: { _ in SettingsTheme.subSettingsHeaderHeight })
        let languagesFooter: ViewState<SectionSeparator> = .cellType(hash: "currencies_header", binder: { view in
            view.bind(showBottomSeparator: false)
        }, dynamicHeight: { _ in SettingsTheme.subSettingsHeaderHeight })

        let itemsCount = items.count
        sections.append(Section(id: "languages", headerState: languagesHeader, footerState: languagesFooter, rows: items.enumerated().map { (index, item) in
            Row<DoubleLineCell>(id: item.id, height: SettingsTheme.languageCellHeight, bind: { cell, _ in
                cell.bind(flagImage: UIImage(named: item.id), title: item.title, subtitle: item.subtitle, selected: item.current, last: index == itemsCount - 1)
            }, action: { [weak self] _ in
                self?.delegate.didSelect(item: item)
            })
        }))

        return sections
    }

}

extension LanguageSettingsViewController: ILanguageSettingsView {

    func set(title: String) {
        self.title = title.localized
    }

    func show(items: [LanguageItem]) {
        self.items = items
    }

}

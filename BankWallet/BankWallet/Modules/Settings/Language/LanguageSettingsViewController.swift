import UIKit
import SectionsTableViewKit

class LanguageSettingsViewController: UIViewController, SectionsDataSource {
    private let delegate: ILanguageSettingsViewDelegate

    private var items = [LanguageItem]()

    let tableView = SectionsTableView(style: .grouped)

    init(delegate: ILanguageSettingsViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        tableView.registerCell(forClass: LanguageCell.self)
        tableView.sectionDataSource = self
        tableView.separatorColor = SettingsTheme.cellSelectBackground

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

        view.backgroundColor = AppTheme.controllerBackground

        delegate.viewDidLoad()
        tableView.reload()
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(Section(id: "languages", headerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), footerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), rows: items.map { item in
            Row<LanguageCell>(id: item.id, height: SettingsTheme.languageCellHeight, bind: { cell, _ in
                cell.selectionStyle = .default
                cell.bind(title: item.title, subtitle: item.subtitle, selected: item.current)
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

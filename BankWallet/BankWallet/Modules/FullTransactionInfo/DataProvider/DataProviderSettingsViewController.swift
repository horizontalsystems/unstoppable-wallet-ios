import UIKit
import SectionsTableView

class DataProviderSettingsViewController: WalletViewController, SectionsDataSource {
    private let delegate: IDataProviderSettingsViewDelegate

    private var items = [DataProviderItem]()

    let tableView = SectionsTableView(style: .grouped)

    init(delegate: IDataProviderSettingsViewDelegate) {
        self.delegate = delegate

        super.init()

        tableView.registerCell(forClass: DataProviderCell.self)
        tableView.sectionDataSource = self
        tableView.separatorColor = SettingsTheme.cellSelectBackground

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "full_info.source.title".localized

        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.prefersLargeTitles = true
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(Section(id: "providers", headerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), footerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), rows: items.map { item in
            Row<DataProviderCell>(id: item.name, height: SettingsTheme.doubleLineCellHeight, bind: { cell, _ in
                cell.bind(title: item.name, online: item.online, checking: item.checking, selected: item.selected)
            }, action: { [weak self] _ in
                self?.delegate.didSelect(item: item)
            })
        }))

        return sections
    }

}

extension DataProviderSettingsViewController: IDataProviderSettingsView {

    func show(items: [DataProviderItem]) {
        self.items = items
        tableView.reload()
    }

}

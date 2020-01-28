import UIKit
import SectionsTableView
import ThemeKit

class DataProviderSettingsViewController: ThemeViewController, SectionsDataSource {
    private let delegate: IDataProviderSettingsViewDelegate

    private var items = [DataProviderItem]()

    private let tableView = SectionsTableView(style: .grouped)

    init(delegate: IDataProviderSettingsViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "full_info.source.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: DataProviderCell.self)
        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        delegate.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.prefersLargeTitles = true
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(Section(
                id: "providers",
                headerState: .margin(height: .margin3x),
                footerState: .margin(height: .margin8x),
                rows: items.enumerated().map { (index, item) in
                    Row<DataProviderCell>(
                            id: item.name,
                            height: .heightDoubleLineCell,
                            bind: { [unowned self] cell, _ in
                                cell.bind(
                                        title: item.name,
                                        online: item.online,
                                        checking: item.checking,
                                        selected: item.selected,
                                        last: index == self.items.count - 1
                                )
                            },
                            action: { [weak self] _ in
                                self?.delegate.didSelect(item: item)
                            }
                    )
                }
        ))

        return sections
    }

}

extension DataProviderSettingsViewController: IDataProviderSettingsView {

    func show(items: [DataProviderItem]) {
        self.items = items
        tableView.reload()
    }

}

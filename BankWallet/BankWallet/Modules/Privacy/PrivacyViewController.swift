import UIKit
import SectionsTableView
import ThemeKit

class PrivacyViewController: ThemeViewController {
    let delegate: IPrivacyViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var sortMode: String?
    private var connectionItems: [PrivacyViewItem]?
    private var syncModeItems: [PrivacyViewItem]?

    init(delegate: IPrivacyViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings_privacy.title".localized

        tableView.registerCell(forClass: PrivacyHeaderCell.self)
        tableView.registerCell(forClass: PrivacyCell.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)

        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.onLoad()
    }

    private func headerSection() -> SectionProtocol {
        let width = view.bounds.width

        return Section(
                id: "header", rows: [
                    Row<PrivacyHeaderCell>(
                            id: "header_cell",
                            dynamicHeight: { _ in
                                PrivacyHeaderCell.height(containerWidth: width)
                            }
                    )
                ]
        )
    }

    private func sortSection(sortModeTitle: String) -> SectionProtocol {
        Section(
                id: "sort",
                headerState: header(hash: "sort_header", text: "settings_privacy.sorting.section_header".localized),
                footerState: footer(hash: "sort_footer", text: "settings_privacy.sorting.section_footer".localized),
                rows: [
                    Row<PrivacyCell>(id: "sorting_cell", hash: "\(sortModeTitle)", height: .heightSingleLineCell, autoDeselect: true, bind: { cell, _ in
                        cell.bind(image: nil, title: "settings_privacy.sorting_title".localized, value: sortModeTitle, showDisclosure: true)
                    }, action: { [weak self] _ in
                        self?.delegate.onSelectSortMode()
                    })
                ]
        )
    }

    private func connectionSection(items: [PrivacyViewItem]) -> SectionProtocol {
        Section(
                id: "connection",
                headerState: header(hash: "connection_header", text: "settings_privacy.connection.section_header".localized),
                footerState: footer(hash: "connection_footer", text: "settings_privacy.connection.section_footer".localized),
                rows: items.enumerated().map { index, item in
                    row(id: "connection_cell", item: item, action: { [weak self] in
                        self?.delegate.onSelectConnection(index: index)
                    })
                }
        )
    }

    private func syncSection(items: [PrivacyViewItem]) -> SectionProtocol {
        Section(
                id: "sync",
                headerState: header(hash: "sync_header", text: "settings_privacy.sync.section_header".localized),
                footerState: footer(hash: "sync_footer", text: "settings_privacy.sync.section_footer".localized),
                rows: items.enumerated().map { index, item in
                    row(id: "sync_cell", item: item, action: { [weak self] in
                        self?.delegate.onSelectSync(index: index)
                    })
                }
        )
    }

    private func row(id: String, item: PrivacyViewItem, action: (() -> ())?) -> RowProtocol {
        Row<PrivacyCell>(id: id, hash: "\(item.title)_\(item.value)_\(item.changable)", height: .heightSingleLineCell, autoDeselect: true, bind: { cell, _ in 
            cell.bind(image: UIImage(named: item.iconName.lowercased()), title: item.title, value: item.value, showDisclosure: item.changable)
        }, action: { _ in
            action?()
        })
    }

    private func header(hash: String, text: String) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: hash,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { _ in
                    SubtitleHeaderFooterView.height
                }
        )
    }

    private func footer(hash: String, text: String) -> ViewState<BottomDescriptionHeaderFooterView> {
        .cellType(
                hash: hash,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { [unowned self] _ in
                    BottomDescriptionHeaderFooterView.height(containerWidth: self.tableView.bounds.width, text: text)
                }
        )
    }

}

extension PrivacyViewController: IPrivacyView {

    func updateUI() {
        tableView.reload()
    }

    func set(sortMode: String) {
        self.sortMode = sortMode
    }

    func set(connectionItems: [PrivacyViewItem]) {
        self.connectionItems = connectionItems
    }

    func set(syncModeItems: [PrivacyViewItem]) {
        self.syncModeItems = syncModeItems
    }

    func showSyncModeAlert(itemIndex: Int, coinName: String, iconName: String, items: [PrivacySyncSelectViewItem]) {
        var alertItems: [BottomAlertItemType] = [
            .title(
                    title: "settings_privacy.alert_sync.title".localized,
                    subtitle: coinName,
                    icon: UIImage(named: iconName.lowercased()),
                    iconTint: .themeGray
            ),
            .description(text: "settings_privacy.alert_sync.description".localized(coinName), important: true, last: false)
        ]

        items.forEach { setting in
            let subtitle = setting.priority == .recommended ? "settings_privacy.alert_sync.recommended" : "settings_privacy.alert_sync.more_private"
            alertItems.append(.radio(title: setting.title, subtitle: subtitle.localized, selected: setting.selected))
        }

        alertItems.append(.button(
                title: "button.done".localized,
                button: .appYellow,
                onTap: { [weak self] selectedIndex in
                    if let selectedIndex = selectedIndex {
                        self?.delegate.onSelectSyncSetting(itemIndex: itemIndex, settingIndex: selectedIndex)
                    }
                }
        ))

        let controller = BottomAlertViewController(items: alertItems)
        present(controller, animated: true)
    }

    func showConnectionModeAlert(itemIndex: Int, coinName: String, iconName: String, items: [PrivacyConnectionSelectViewItem]) {
        var alertItems: [BottomAlertItemType] = [
            .title(
                    title: "settings_privacy.alert_connection.title".localized,
                    subtitle: coinName,
                    icon: UIImage(named: iconName.lowercased()),
                    iconTint: .themeGray
            )
        ]

        items.forEach { setting in
            alertItems.append(.radio(title: setting.title, subtitle: setting.subtitle, selected: setting.selected))
        }

        alertItems.append(.button(
                title: "button.done".localized,
                button: .appYellow,
                onTap: { [weak self] selectedIndex in
                    if let selectedIndex = selectedIndex {
                        self?.delegate.onSelectConnectionSetting(itemIndex: itemIndex, settingIndex: selectedIndex)
                    }
                }
        ))

        let controller = BottomAlertViewController(items: alertItems)
        present(controller, animated: true)
    }

}

extension PrivacyViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(headerSection())

        if let sortMode = sortMode {
            sections.append(sortSection(sortModeTitle: sortMode))
        }

        if let connectionItems = connectionItems {
            sections.append(connectionSection(items: connectionItems))
        }

        if let syncModeItems = syncModeItems {
            sections.append(syncSection(items: syncModeItems))
        }

        return sections
    }

}

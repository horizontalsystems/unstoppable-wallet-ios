import UIKit
import SectionsTableView
import ThemeKit
import ComponentKit

class PrivacyViewController: ThemeViewController {
    let delegate: IPrivacyViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var sortMode: String?
    private var syncModeItems: [PrivacyViewItem]?

    init(delegate: IPrivacyViewDelegate) {
        self.delegate = delegate

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings_privacy.title".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "circle_information_24")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(onTapInfo))
        navigationItem.rightBarButtonItem?.tintColor = .themeJacob

        tableView.registerCell(forClass: HighlightedDescriptionCell.self)
        tableView.registerCell(forClass: A5Cell.self)
        tableView.registerCell(forClass: B5Cell.self)
        tableView.registerCell(forClass: A7Cell.self)
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

    @objc private func onTapInfo() {
        delegate.onTapInfo()
    }

    private func headerSection() -> SectionProtocol {
        let text = "settings_privacy.header_description".localized

        return Section(
                id: "header",
                footerState: .margin(height: .margin3x),
                rows: [
                    Row<HighlightedDescriptionCell>(
                            id: "header_cell",
                            dynamicHeight: { containerWidth in
                                HighlightedDescriptionCell.height(containerWidth: containerWidth, text: text)
                            },
                            bind: { cell, _ in
                                cell.descriptionText = text
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
                    Row<B5Cell>(
                            id: "sorting_cell",
                            hash: "\(sortModeTitle)",
                            height: .heightCell48,
                            autoDeselect: true,
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                                cell.title = "settings_privacy.sorting_title".localized
                                cell.value = sortModeTitle
                            },
                            action: { [weak self] _ in
                                self?.delegate.onSelectSortMode()
                            }
                    )
                ]
        )
    }

    private func syncSection(items: [PrivacyViewItem]) -> SectionProtocol {
        Section(
                id: "sync",
                headerState: header(hash: "sync_header", text: "settings_privacy.sync.section_header".localized),
                footerState: footer(hash: "sync_footer", text: "settings_privacy.sync.section_footer".localized),
                rows: items.enumerated().map { index, item in
                    row(id: "sync_cell", item: item, isFirst: index == 0, isLast: index == items.count - 1, action: { [weak self] in
                        self?.delegate.onSelectSync(index: index)
                    })
                }
        )
    }

    private func row(id: String, item: PrivacyViewItem, isFirst: Bool, isLast: Bool, action: (() -> ())?) -> RowProtocol {
        if item.changeable {
            return Row<A5Cell>(
                    id: id,
                    hash: "\(item.value)",
                    height: .heightCell48,
                    autoDeselect: true,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                        cell.titleImage = UIImage(named: item.iconName)
                        cell.set(titleImageSize: .iconSize24)
                        cell.title = item.title
                        cell.value = item.value
                    },
                    action: { _ in
                        action?()
                    }
            )
        } else {
            return Row<A7Cell>(
                    id: id,
                    hash: "\(item.value)",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                        cell.titleImage = UIImage(named: item.iconName)
                        cell.set(titleImageSize: .iconSize24)
                        cell.title = item.title
                        cell.value = item.value
                    }
            )
        }
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
                dynamicHeight: { containerWidth in
                    BottomDescriptionHeaderFooterView.height(containerWidth: containerWidth, text: text)
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

    func set(syncModeItems: [PrivacyViewItem]) {
        self.syncModeItems = syncModeItems
    }

}

extension PrivacyViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(headerSection())

        if let sortMode = sortMode {
            sections.append(sortSection(sortModeTitle: sortMode))
        }

        if let syncModeItems = syncModeItems {
            sections.append(syncSection(items: syncModeItems))
        }

        return sections
    }

}

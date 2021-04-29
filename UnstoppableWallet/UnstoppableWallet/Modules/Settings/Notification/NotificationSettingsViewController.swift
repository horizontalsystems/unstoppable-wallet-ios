import UIKit
import SectionsTableView
import ThemeKit
import ComponentKit

class NotificationSettingsViewController: ThemeViewController {
    private let delegate: INotificationSettingsViewDelegate

    private var pushNotificationsOn = false
    private var viewItems = [NotificationSettingSectionViewItem]()
    private var showResetAll = false

    private let tableView = SectionsTableView(style: .grouped)
    private let warningView = UIView()

    init(delegate: INotificationSettingsViewDelegate) {
        self.delegate = delegate

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings_notifications.title".localized

        tableView.registerCell(forClass: B11Cell.self)
        tableView.registerCell(forClass: B5Cell.self)
        tableView.registerCell(forClass: BCell.self)
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)

        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        warningView.isHidden = true

        view.addSubview(warningView)
        warningView.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(view.safeAreaLayoutGuide)
            maker.leading.trailing.equalToSuperview()
        }

        let warningLabel = UILabel()
        warningLabel.numberOfLines = 0
        warningLabel.font = .subhead2
        warningLabel.textColor = .themeGray
        warningLabel.text = "settings.notifications.disabled_text".localized

        warningView.addSubview(warningLabel)
        warningLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
        }

        let settingsButton = ThemeButton().apply(style: .secondaryDefault)
        settingsButton.setTitle("settings.notifications.settings_button".localized, for: .normal)
        settingsButton.addTarget(self, action: #selector(onTapSettingsButton), for: .touchUpInside)

        warningView.addSubview(settingsButton)
        settingsButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(warningLabel.snp.bottom).offset(CGFloat.margin8x)
        }

        delegate.viewDidLoad()
        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc func onTapSettingsButton() {
        delegate.didTapSettingsButton()
    }

}

extension NotificationSettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [toggleNotificationsSection()]

        sections.append(contentsOf: itemSections(viewItems: viewItems))

        if showResetAll {
            sections.append(resetAllSection())
        }

        return sections
    }

    private func toggleNotificationsSection() -> SectionProtocol {
        let description = "settings_notifications.description".localized
        let footerState: ViewState<BottomDescriptionHeaderFooterView> = .cellType(hash: "toggle_description", binder: { view in
            view.bind(text: description)
        }, dynamicHeight: { containerWidth in
            BottomDescriptionHeaderFooterView.height(containerWidth: containerWidth, text: description)
        })

        return Section(
                id: "toggle_section",
                headerState: .margin(height: .margin3x),
                footerState: footerState,
                rows: [
                    Row<B11Cell>(
                            id: "toggle_cell",
                            hash: "\(pushNotificationsOn)",
                            height: .heightCell48,
                            bind: { [weak self] cell, _ in
                                cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                                cell.title = "settings_notifications.toggle_title".localized
                                cell.isOn = self?.pushNotificationsOn ?? false
                                cell.onToggle = { [weak self] isOn in
                                    self?.delegate.didToggleNotifications(on: isOn)
                                }
                            }
                    )
                ]
        )
    }

    private func itemSections(viewItems: [NotificationSettingSectionViewItem]) -> [SectionProtocol] {
        viewItems.enumerated().map { index, viewItem in
            itemSection(sectionIndex: index, viewItem: viewItem)
        }
    }

    private func itemSection(sectionIndex: Int, viewItem: NotificationSettingSectionViewItem) -> SectionProtocol {
        let headerState: ViewState<SubtitleHeaderFooterView> = .cellType(hash: "item_section_header_\(sectionIndex)", binder: { view in
            view.bind(text: viewItem.title)
        }, dynamicHeight: { containerWidth in
            SubtitleHeaderFooterView.height
        })

        let itemsCount = viewItem.rowItems.count

        return Section(
                id: "item_section_\(sectionIndex)",
                headerState: headerState,
                footerState: .margin(height: 20),
                rows: viewItem.rowItems.enumerated().compactMap { [weak self] index, item in
                    self?.itemRow(index: index, viewItem: item, isFirst: index == 0, isLast: index == itemsCount - 1)
                }
        )
    }

    private func itemRow(index: Int, viewItem: NotificationSettingRowViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        Row<B5Cell>(
                id: "item_row_\(index)",
                hash: "\(viewItem.value)",
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                    cell.title = viewItem.title.localized
                    cell.value = viewItem.value
                },
                action: { _ in
                    viewItem.onTap()
                }
        )
    }

    private func resetAllSection() -> SectionProtocol {
        Section(
                id: "reset_all_section",
                headerState: .margin(height: .margin3x),
                footerState: .margin(height: .margin8x),
                rows: [
                    Row<BCell>(
                            id: "reset_all_cell",
                            height: .heightCell48,
                            autoDeselect: true,
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                                cell.title = "settings_notifications.reset_all_title".localized
                                cell.titleColor = .themeLucian
                            },
                            action: { [weak self] _ in
                                self?.delegate.didTapDeactivateAll()
                            }
                    )
                ]
        )
    }

}

extension NotificationSettingsViewController: INotificationSettingsView {

    func set(pushNotificationsOn: Bool) {
        self.pushNotificationsOn = pushNotificationsOn

        tableView.reload()
    }

    func set(viewItems: [NotificationSettingSectionViewItem], showResetAll: Bool) {
        self.viewItems = viewItems
        self.showResetAll = showResetAll
        tableView.reload()
    }

    func showWarning() {
        warningView.isHidden = false
        tableView.isHidden = true
    }

    func hideWarning() {
        warningView.isHidden = true
        tableView.isHidden = false
    }

    func showError(error: Error) {
        HudHelper.instance.showError(title: error.smartDescription)
    }

}

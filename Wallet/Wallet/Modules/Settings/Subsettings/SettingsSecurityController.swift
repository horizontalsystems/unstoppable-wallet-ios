import UIKit
import SectionsTableViewKit

class SettingsSecurityController: UIViewController, SectionsDataSource {
    let tableView = SectionsTableView(style: .grouped)

    init() {
        super.init(nibName: nil, bundle: nil)
        tableView.registerCell(forClass: SettingsCell.self)
        tableView.registerCell(forClass: SettingsRightImageCell.self)
        tableView.registerCell(forClass: SettingsToggleCell.self)
        tableView.sectionDataSource = self
        tableView.separatorColor = SettingsTheme.separatorColor

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

        title = "settings_security.title".localized

        view.backgroundColor = AppTheme.controllerBackground

        tableView.reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        var pinTouchFaceRows = [RowProtocol]()
        pinTouchFaceRows.append(Row<SettingsToggleCell>(id: "touch_face_id", height: SettingsTheme.securityCellHeight, bind: { cell, _ in
            cell.bind(titleIcon: nil, title: "settings_pin_touch_face.touch_id".localized, isOn: false, showDisclosure: false, onToggle: { isOn in
                print("on: \(isOn)")
            })
        }))
        let setChangePinTitle = UnlockHelper.shared.isPinned ? "settings_pin_touch_face.change_pin".localized : "settings_pin_touch_face.set_pin".localized
        pinTouchFaceRows.append(Row<SettingsCell>(id: "set_pin", height: SettingsTheme.securityCellHeight, bind: { cell, _ in
            cell.bind(titleIcon: nil, title: setChangePinTitle, showDisclosure: true, last: true)
        }, action: { [weak self] _ in
            self?.navigationController?.pushViewController(PinRouter.setPinModule(), animated: true)
        }))
        sections.append(Section(id: "security", headerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), footerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), rows: pinTouchFaceRows))

        var backupRows = [RowProtocol]()
        backupRows.append(Row<SettingsCell>(id: "paper_key", height: SettingsTheme.securityCellHeight, bind: { cell, _ in
            cell.bind(titleIcon: nil, title: "settings_security.paper_key".localized, showDisclosure: true)
        }, action: { [weak self] _ in
            self?.tableView.deselectRow(at: self!.tableView.indexPathForSelectedRow!, animated: true)
            self?.present(BackupRouter.module(dismissMode: .dismissSelf), animated: true)
        }))
        sections.append(Section(id: "security", headerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), footerState: .margin(height: SettingsTheme.headerHeight), rows: backupRows))

        return sections
    }

    func applyLanguage(language: String) {
        UserDefaultsStorage.shared.currentLanguage = language
        LocalizationHelper.instance.update(language: language)

        if let window = UIApplication.shared.keyWindow {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = LaunchRouter.module()
            })
        }
    }
}

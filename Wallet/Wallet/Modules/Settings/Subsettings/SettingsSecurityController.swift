import UIKit
import SectionsTableViewKit

class SettingsSecurityController: UIViewController, SectionsDataSource {
    let tableView = SectionsTableView(style: .grouped)

    init() {
        super.init(nibName: nil, bundle: nil)
        tableView.registerCell(forClass: SecurityCell.self)
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

        title = "settings_security.title".localized

        view.backgroundColor = AppTheme.controllerBackground

        tableView.reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        var rows = [RowProtocol]()
        rows.append(Row<SecurityCell>(id: "pin_touch_id", height: SettingsTheme.securityCellHeight, bind: { cell, _ in
            cell.bind(title: "settings_security.pin_touch_id".localized, checked: true)
        }, action: { [weak self] _ in
            self?.navigationController?.pushViewController(PinRouter.setPinModule(), animated: true)
        }))
        rows.append(Row<SecurityCell>(id: "paper_key", height: SettingsTheme.securityCellHeight, bind: { cell, _ in
            cell.bind(title: "settings_security.paper_key".localized, checked: false)
        }, action: { [weak self] _ in
            self?.tableView.deselectRow(at: self!.tableView.indexPathForSelectedRow!, animated: true)
            self?.present(BackupRouter.module(dismissMode: .dismissSelf), animated: true)
        }))
        sections.append(Section(id: "security", headerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), footerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), rows: rows))

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

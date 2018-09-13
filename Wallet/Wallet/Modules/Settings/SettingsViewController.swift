import UIKit
import GrouviExtensions
import SectionsTableViewKit
import SnapKit

class SettingsViewController: UIViewController, SectionsDataSource {

    let viewDelegate: SettingsViewDelegate

    let tableView = SectionsTableView(style: .grouped)

    init(viewDelegate: SettingsViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: nil, bundle: nil)

        tabBarItem = UITabBarItem(title: "settings.tab_bar_item".localized, image: UIImage(named: "settings.tab_bar_item"), tag: 0)

        tableView.registerCell(forClass: SettingsCell.self)
        tableView.registerCell(forClass: SettingsRightImageCell.self)
        tableView.registerCell(forClass: SettingsRightLabelCell.self)
        tableView.registerCell(forClass: SettingsToggleCell.self)
        tableView.registerHeaderFooter(forClass: SettingsInfoFooter.self)
        tableView.sectionDataSource = self
        tableView.separatorColor = SettingsTheme.cellBackground
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

        title = "settings.title".localized

        view.backgroundColor = AppTheme.controllerBackground

        tableView.reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        var appSettingsRows = [RowProtocol]()
        appSettingsRows.append(Row<SettingsRightImageCell>(id: "security_center", hash: "security_center", height: SettingsTheme.cellHeight, bind: { cell, _ in
            cell.selectionStyle = .default
            cell.bind(titleIcon: UIImage(named: "Security Icon"), title: "settings.cell.security_center".localized, rightImage: UIImage(named: "Attention Icon"), rightImageTintColor: SettingsTheme.attentionIconTint, showDisclosure: true)
        }, action: { [weak self] _ in
            self?.navigationController?.pushViewController(SettingsSecurityController(), animated: true)
        }))
        appSettingsRows.append(Row<SettingsCell>(id: "import_wallet", hash: "import_wallet", height: SettingsTheme.cellHeight, bind: { cell, _ in
            cell.selectionStyle = .default
            cell.bind(titleIcon: UIImage(named: "Import Wallet Icon"), title: "settings.cell.import_wallet".localized, showDisclosure: true, last: true)
        }, action: { _ in
            print("tap import wallet")
        }))
        sections.append(Section(id: "app_settings", headerState: .marginColor(height: SettingsTheme.topHeaderHeight, color: .clear), rows: appSettingsRows))

        var appearanceRows = [RowProtocol]()
        appearanceRows.append(Row<SettingsRightLabelCell>(id: "base_currency", hash: "base_currency", height: SettingsTheme.cellHeight, bind: { cell, _ in
            cell.selectionStyle = .default
            cell.bind(titleIcon: UIImage(named: "Currency Icon"), title: "settings.cell.base_currency".localized, rightText: "n/a", showDisclosure: true)
        }, action: { _ in
            print("tap base currency")
        }))
        appearanceRows.append(Row<SettingsCell>(id: "language", hash: "language", height: SettingsTheme.cellHeight, bind: { cell, _ in
            cell.selectionStyle = .default
            cell.bind(titleIcon: UIImage(named: "Language Icon"), title: "settings.cell.language".localized, showDisclosure: true)
        }, action: { [weak self] _ in
            self?.navigationController?.pushViewController(SettingsLanguageController(), animated: true)
        }))
        appearanceRows.append(Row<SettingsToggleCell>(id: "light_mode", hash: "light_mode", height: SettingsTheme.cellHeight, bind: { cell, _ in
            cell.selectionStyle = .none
            cell.bind(titleIcon: UIImage(named: "Light Mode Icon"), title: "settings.cell.light_mode".localized, isOn: UserDefaultsStorage.shared.lightMode, showDisclosure: false, last: true, onToggle: { isOn in
                UserDefaultsStorage.shared.lightMode = isOn

                if let window = UIApplication.shared.keyWindow {
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                        window.rootViewController = LaunchRouter.module()
                    })
                }
            })
        }))
        sections.append(Section(id: "appearance_settings", headerState: .marginColor(height: SettingsTheme.headerHeight, color: .clear), rows: appearanceRows))

        var aboutRows = [RowProtocol]()
        aboutRows.append(Row<SettingsCell>(id: "about", hash: "about", height: SettingsTheme.cellHeight, bind: { cell, _ in
            cell.selectionStyle = .default
            cell.bind(titleIcon: UIImage(named: "About Icon"), title: "settings.cell.about".localized, showDisclosure: true, last: true)
        }, action: { _ in
            print("tap about")
        }))
        let infoFooter: ViewState<SettingsInfoFooter> = .cellType(hash: "info_view", binder: { view in
            view.logoButton.handleTouch = {
                UIApplication.shared.open(URL(string: "http://horizontalsystems.io/")!)
            }
        }, dynamicHeight: { _ in SettingsTheme.infoFooterHeight })
        sections.append(Section(id: "appearance_settings", headerState: .marginColor(height: SettingsTheme.headerHeight, color: .clear), footerState: infoFooter, rows: aboutRows))

        var debugRows = [RowProtocol]()
        debugRows.append(Row<SettingsCell>(id: "debug_logout", hash: "debug_logout", height: SettingsTheme.cellHeight, bind: { cell, _ in
            cell.selectionStyle = .default
            cell.bind(titleIcon: UIImage(named: "Bug Icon"), title: "Logout", showDisclosure: false)
        }, action: { [weak self] _ in
            self?.logout()
            self?.tableView.deselectRow(at: self!.tableView.indexPathForSelectedRow!, animated: true)
        }))
        debugRows.append(Row<SettingsCell>(id: "debug_realm_info", hash: "debug_realm_info", height: SettingsTheme.cellHeight, bind: { cell, _ in
            cell.selectionStyle = .default
            cell.bind(titleIcon: UIImage(named: "Bug Icon"), title: "Show Realm Info", showDisclosure: false)
        }, action: { [weak self] _ in
            self?.showRealmInfo()
            self?.tableView.deselectRow(at: self!.tableView.indexPathForSelectedRow!, animated: true)
        }))
        debugRows.append(Row<SettingsCell>(id: "debug_connect_to_peer", hash: "debug_connect_to_peer", height: SettingsTheme.cellHeight, bind: { cell, _ in
            cell.selectionStyle = .default
            cell.bind(titleIcon: UIImage(named: "Bug Icon"), title: "Connect to Peer", showDisclosure: false)
        }, action: { [weak self] _ in
            self?.connectToPeer()
            self?.tableView.deselectRow(at: self!.tableView.indexPathForSelectedRow!, animated: true)
        }))
        sections.append(Section(id: "debug_section", headerState: .marginColor(height: 50, color: .clear), footerState: .marginColor(height: 20, color: .clear), rows: debugRows))

        return sections
    }

    func logout() {
        WordsManager.shared.removeWords()
        AdapterManager.shared.clear()

        guard let window = UIApplication.shared.keyWindow else {
            return
        }

        let viewController = GuestRouter.module()

        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
            window.rootViewController = viewController
        })
    }

    @IBAction func showRealmInfo() {
        for adapter in AdapterManager.shared.adapters {
            print("\nINFO FOR \(adapter.coin.name):")
            adapter.showInfo()
        }
    }

    @IBAction func connectToPeer() {
        AdapterManager.shared.start()
    }

}

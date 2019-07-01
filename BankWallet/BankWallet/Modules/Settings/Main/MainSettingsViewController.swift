import UIKit
import UIExtensions
import SectionsTableView
import SnapKit

class MainSettingsViewController: WalletViewController, SectionsDataSource {
    let delegate: IMainSettingsViewDelegate

    let tableView = SectionsTableView(style: .grouped)

    var backedUp = false
    var baseCurrency = "n/a"
    var language = ""
    var lightMode = true
    var appVersion = ""

    var didLoad = false

    init(delegate: IMainSettingsViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        title = "settings.title".localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)

        tabBarItem = UITabBarItem(title: "settings.tab_bar_item".localized, image: UIImage(named: "settings.tab_bar_item"), tag: 0)

        tableView.registerCell(forClass: SettingsCell.self)
        tableView.registerCell(forClass: SettingsRightImageCell.self)
        tableView.registerCell(forClass: SettingsRightLabelCell.self)
        tableView.registerCell(forClass: SettingsToggleCell.self)
        tableView.registerHeaderFooter(forClass: SectionSeparator.self)
        tableView.registerHeaderFooter(forClass: SettingsInfoFooter.self)
        tableView.sectionDataSource = self
        tableView.separatorColor = .clear
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
        didLoad = true
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        var securitySettingsRows = [RowProtocol]()
        let securityAttentionImage = backedUp ? nil : UIImage(named: "Attention Icon")
        securitySettingsRows.append(Row<SettingsRightImageCell>(id: "security_center", hash: "security_center.\(backedUp)", height: SettingsTheme.cellHeight, bind: { cell, _ in
            cell.selectionStyle = .default
            cell.bind(titleIcon: UIImage(named: "Security Icon"), title: "settings.security_center".localized, rightImage: securityAttentionImage, rightImageTintColor: SettingsTheme.attentionIconTint, showDisclosure: true)
        }, action: { [weak self] _ in
            self?.delegate.didTapSecurity()
        }))
        securitySettingsRows.append(Row<SettingsCell>(id: "restore", hash: "restore", height: SettingsTheme.cellHeight, bind: { cell, _ in
            cell.selectionStyle = .default
            cell.bind(titleIcon: UIImage(named: "Restore Icon"), title: "settings.restore_wallet".localized, showDisclosure: true, last: true)
        }, action: { [weak self] _ in
            self?.delegate.didTapRestore()
        }))
        let settingsHeader: ViewState<SectionSeparator> = .cellType(hash: "settings_header", binder: { view in
            view.bind(showTopSeparator: false)
        }, dynamicHeight: { _ in SettingsTheme.topHeaderHeight })
        sections.append(Section(id: "app_settings", headerState: settingsHeader, rows: securitySettingsRows))

        var appearanceRows = [RowProtocol]()
        appearanceRows.append(Row<SettingsRightLabelCell>(id: "base_currency", hash: "base_currency", height: SettingsTheme.cellHeight, bind: { [weak self] cell, _ in
            cell.selectionStyle = .default
            cell.bind(titleIcon: UIImage(named: "Currency Icon"), title: "settings.base_currency".localized, rightText: self?.baseCurrency, showDisclosure: true)
        }, action: { [weak self] _ in
            self?.delegate.didTapBaseCurrency()
        }))
        appearanceRows.append(Row<SettingsRightLabelCell>(id: "language", hash: "language", height: SettingsTheme.cellHeight, bind: { [weak self] cell, _ in
            cell.selectionStyle = .default
            cell.bind(titleIcon: UIImage(named: "Language Icon"), title: "settings.language".localized, rightText: self?.language, showDisclosure: true)
        }, action: { [weak self] _ in
            self?.delegate.didTapLanguage()
        }))
        appearanceRows.append(Row<SettingsToggleCell>(id: "light_mode", hash: "light_mode", height: SettingsTheme.cellHeight, bind: { [weak self] cell, _ in
            cell.bind(titleIcon: UIImage(named: "Light Mode Icon"), title: "settings.light_mode".localized, isOn: self?.lightMode ?? false, showDisclosure: false, last: true, onToggle: { isOn in
                self?.delegate.didSwitch(lightMode: isOn)
            })
        }))
        let appearanceHeader: ViewState<SectionSeparator> = .cellType(hash: "appearance_header", binder: nil, dynamicHeight: { _ in SettingsTheme.headerHeight })
        sections.append(Section(id: "appearance_settings", headerState: appearanceHeader, rows: appearanceRows))

        var aboutRows = [RowProtocol]()
        aboutRows.append(Row<SettingsCell>(id: "about", hash: "about", height: SettingsTheme.cellHeight, bind: { cell, _ in
            cell.selectionStyle = .default
            cell.bind(titleIcon: UIImage(named: "About Icon"), title: "settings.about".localized, showDisclosure: true, last: true)
        }, action: { [weak self] _ in
            self?.delegate.didTapAbout()
        }))
        let infoHeader: ViewState<SectionSeparator> = .cellType(hash: "info_header", binder: nil, dynamicHeight: { _ in SettingsTheme.headerHeight })
        let infoFooter: ViewState<SettingsInfoFooter> = .cellType(hash: "info_footer", binder: { [weak self] view in
            self?.bindFooter(view: view)
        }, dynamicHeight: { _ in SettingsTheme.infoFooterHeight })
        sections.append(Section(id: "info_settings", headerState: infoHeader, footerState: infoFooter, rows: aboutRows))

#if DEBUG
        var debugRows = [RowProtocol]()
        debugRows.append(Row<SettingsCell>(id: "debug_realm_info", hash: "debug_realm_info", height: SettingsTheme.cellHeight, autoDeselect: true, bind: { cell, _ in
            cell.selectionStyle = .default
            cell.bind(titleIcon: UIImage(named: "Bug Icon"), title: "Show Realm Info", showDisclosure: false)
        }, action: { [weak self] _ in
            self?.showRealmInfo()
        }))
//        debugRows.append(Row<SettingsCell>(id: "debug_drop_keychain", hash: "debug_drop_keychain", height: SettingsTheme.cellHeight, autoDeselect: true, bind: { cell, _ in
//            cell.selectionStyle = .default
//            cell.bind(titleIcon: UIImage(named: "Bug Icon"), title: "Drop Keychain", showDisclosure: false)
//        }, action: { _ in
//            App.shared.localStorage.isBackedUp = false
//            try? App.shared.pinManager.store(pin: nil)
//        }))
        sections.append(Section(id: "debug_section", headerState: .marginColor(height: 50, color: .clear), footerState: .marginColor(height: 20, color: .clear), rows: debugRows))
#endif

        return sections
    }

    func bindFooter(view: SettingsInfoFooter) {
        view.bind(appVersion: appVersion) { [weak self] in
            self?.delegate.didTapAppLink()
        }
    }

    private func showRealmInfo() {
        for adapter in App.shared.adapterManager.adapters {
            print("\nINFO FOR \(adapter.wallet.coin.code):\n\(adapter.debugInfo)")
        }
    }

    private func reloadIfNeeded() {
        if didLoad {
            tableView.reload()
        }
    }

}

extension MainSettingsViewController: IMainSettingsView {

    func set(backedUp: Bool) {
        self.backedUp = backedUp
        reloadIfNeeded()
    }

    func set(baseCurrency: String) {
        self.baseCurrency = baseCurrency
        reloadIfNeeded()
    }

    func set(language: String) {
        self.language = language
    }

    func set(lightMode: Bool) {
        self.lightMode = lightMode
    }

    func set(appVersion: String) {
        self.appVersion = appVersion
    }

    func setTabItemBadge(count: Int) {
        navigationController?.tabBarItem.badgeValue = count == 0 ? nil : "!"
    }

}

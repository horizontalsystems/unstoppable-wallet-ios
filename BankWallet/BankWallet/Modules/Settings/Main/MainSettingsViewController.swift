import UIKit
import SectionsTableView
import SnapKit
import ThemeKit

class MainSettingsViewController: ThemeViewController {
    private let delegate: IMainSettingsViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var allBackedUp: Bool = true
    private var currentBaseCurrency: String?
    private var currentLanguage: String?
    private var lightMode: Bool = true
    private var appVersion: String?

    init(delegate: IMainSettingsViewDelegate) {
        self.delegate = delegate

        super.init()

        tabBarItem = UITabBarItem(title: "settings.tab_bar_item".localized, image: UIImage(named: "settings.tab_bar_item"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings.title".localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)

        tableView.registerCell(forClass: TitleCell.self)
        tableView.registerCell(forClass: RightImageCell.self)
        tableView.registerCell(forClass: RightLabelCell.self)
        tableView.registerCell(forClass: ToggleCell.self)
        tableView.registerHeaderFooter(forClass: MainSettingsFooter.self)

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()

        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    private var securityRows: [RowProtocol] {
        let securityAttentionImage = allBackedUp ? nil : UIImage(named: "Attention Icon")

        return [
            Row<TitleCell>(id: "manage_coins", height: .heightSingleLineCell, bind: { cell, _ in
                cell.bind(titleIcon: UIImage(named: "Manage Coins Icon"), title: "settings.manage_coins".localized, showDisclosure: true)
            }, action: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.delegate.didTapManageCoins()
                }
            }),

            Row<RightImageCell>(id: "security_center", hash: "security_center.\(allBackedUp)", height: .heightSingleLineCell, bind: { cell, _ in
                cell.bind(titleIcon: UIImage(named: "Security Icon"), title: "settings.security_center".localized, rightImage: securityAttentionImage, rightImageTintColor: .themeLucian, showDisclosure: true)
            }, action: { [weak self] _ in
                self?.delegate.didTapSecurity()
            }),

            Row<TitleCell>(id: "experimental_features", height: .heightSingleLineCell, bind: { cell, _ in
                cell.bind(titleIcon: UIImage(named: "Experimental Features Icon"), title: "settings.experimental_features".localized, showDisclosure: true, last: true)
            }, action: { [weak self] _ in
                self?.delegate.didTapExperimentalFeatures()
            })
        ]
    }

    private var appearanceRows: [RowProtocol] {
        [
//            Row<TitleCell>(id: "notifications", height: SettingsTheme.cellHeight, bind: { cell, _ in
//                cell.bind(titleIcon: UIImage(named: "Notification Icon"), title: "settings.notifications".localized, showDisclosure: true)
//            }, action: { [weak self] _ in
//                self?.delegate.didTapNotifications()
//            }),

            Row<RightLabelCell>(id: "base_currency", height: .heightSingleLineCell, bind: { [weak self] cell, _ in
                cell.bind(titleIcon: UIImage(named: "Currency Icon"), title: "settings.base_currency".localized, rightText: self?.currentBaseCurrency, showDisclosure: true)
            }, action: { [weak self] _ in
                self?.delegate.didTapBaseCurrency()
            }),

            Row<RightLabelCell>(id: "language", height: .heightSingleLineCell, bind: { [weak self] cell, _ in
                cell.bind(titleIcon: UIImage(named: "Language Icon"), title: "settings.language".localized, rightText: self?.currentLanguage, showDisclosure: true)
            }, action: { [weak self] _ in
                self?.delegate.didTapLanguage()
            }),

            Row<ToggleCell>(id: "light_mode", height: .heightSingleLineCell, bind: { [unowned self] cell, _ in
                cell.bind(titleIcon: UIImage(named: "Light Mode Icon"), title: "settings.light_mode".localized, isOn: self.lightMode, last: true, onToggle: { [weak self] isOn in
                    self?.delegate.didSwitch(lightMode: isOn)
                })
            })
        ]
    }

    private var aboutRows: [RowProtocol] {
        [
            Row<TitleCell>(id: "about", height: .heightSingleLineCell, bind: { cell, _ in
                cell.bind(titleIcon: UIImage(named: "About Icon"), title: "settings.about".localized, showDisclosure: true)
            }, action: { [weak self] _ in
                self?.delegate.didTapAbout()
            }),

            Row<TitleCell>(id: "tell_friends", height: .heightSingleLineCell, autoDeselect: true, bind: { cell, _ in
                cell.bind(titleIcon: UIImage(named: "Tell Friends Icon"), title: "settings.tell_friends".localized, showDisclosure: true)
            }, action: { [weak self] _ in
                self?.delegate.didTapTellFriends()
            }),

            Row<TitleCell>(id: "contact", height: .heightSingleLineCell, bind: { cell, _ in
                cell.bind(titleIcon: UIImage(named: "Contact Icon"), title: "settings.contact".localized, showDisclosure: true, last: true)
            }, action: { [weak self] _ in
                self?.delegate.didTapContact()
            })
        ]
    }

    private var debugRows: [RowProtocol] {
        [
            Row<TitleCell>(id: "debug_realm_info", height: .heightSingleLineCell, autoDeselect: true, bind: { cell, _ in
                cell.bind(titleIcon: UIImage(named: "Bug Icon"), title: "Show Realm Info", showDisclosure: false, last: false)
            }, action: { [weak self] _ in
                self?.showRealmInfo()
            })
        ]
    }

    private var footer: ViewState<MainSettingsFooter> {
        .cellType(hash: "about_footer", binder: { [weak self] view in
            view.bind(appVersion: self?.appVersion) { [weak self] in
                self?.delegate.didTapCompanyLink()
            }
        }, dynamicHeight: { _ in
            194
        })
    }

    private func showRealmInfo() {
        for wallet in App.shared.walletManager.wallets {
            print("\nINFO FOR \(wallet.coin.code):")
            if let adapter = App.shared.adapterManager.adapter(for: wallet) {
                print(adapter.debugInfo)
            }
        }
    }

}

extension MainSettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(id: "security_settings", headerState: .margin(height: .margin3x), rows: securityRows),
            Section(id: "appearance_settings", headerState: .margin(height: .margin8x), rows: appearanceRows),
            Section(id: "about", headerState: .margin(height: .margin8x), footerState: footer, rows: aboutRows)
        ]

        #if DEBUG
        sections.append(Section(id: "debug", headerState: .margin(height: 50), footerState: .margin(height: 20), rows: debugRows))
        #endif

        return sections
    }

}

extension MainSettingsViewController: IMainSettingsView {

    func refresh() {
        tableView.reload()
    }

    func set(allBackedUp: Bool) {
        self.allBackedUp = allBackedUp
    }

    func set(currentBaseCurrency: String) {
        self.currentBaseCurrency = currentBaseCurrency
    }

    func set(currentLanguage: String?) {
        self.currentLanguage = currentLanguage
    }

    func set(lightMode: Bool) {
        self.lightMode = lightMode
    }

    func set(appVersion: String) {
        self.appVersion = appVersion
    }

}

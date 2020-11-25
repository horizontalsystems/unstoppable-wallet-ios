import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import UIExtensions

class MainSettingsViewController: ThemeViewController {
    private let delegate: IMainSettingsViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private let manageAccountsCell = A3Cell()
    private let securityCenterCell = A3Cell()
    private let walletConnectCell = A2Cell()
    private let baseCurrencyCell = A2Cell()
    private let languageCell = A2Cell()
    private let lightModeCell = A11Cell()
    private let aboutCell = A3Cell()
    private let footerCell = MainSettingsFooterCell()

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

        tableView.registerCell(forClass: A1Cell.self)

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }


        manageAccountsCell.set(backgroundStyle: .lawrence)
        manageAccountsCell.titleImage = UIImage(named: "wallet_20")
        manageAccountsCell.title = "settings.manage_accounts".localized

        securityCenterCell.set(backgroundStyle: .lawrence, bottomSeparator: true)
        securityCenterCell.titleImage = UIImage(named: "security_20")
        securityCenterCell.title = "settings.security_center".localized

        walletConnectCell.set(backgroundStyle: .lawrence, bottomSeparator: true)
        walletConnectCell.titleImage = UIImage(named: "wallet_connect_20")
        walletConnectCell.title = "wallet_connect.title".localized

        baseCurrencyCell.set(backgroundStyle: .lawrence)
        baseCurrencyCell.titleImage = UIImage(named: "currency_20")
        baseCurrencyCell.title = "settings.base_currency".localized

        languageCell.set(backgroundStyle: .lawrence)
        languageCell.titleImage = UIImage(named: "language_20")
        languageCell.title = "settings.language".localized

        lightModeCell.set(backgroundStyle: .lawrence)
        lightModeCell.titleImage = UIImage(named: "light_mode_20")
        lightModeCell.title = "settings.light_mode".localized
        lightModeCell.onToggle = { [weak self] isOn in
            self?.delegate.didSwitch(lightMode: isOn)
        }

        aboutCell.set(backgroundStyle: .lawrence, bottomSeparator: true)
        aboutCell.titleImage = UIImage(named: "uw_20")
        aboutCell.title = "settings.about_app.title".localized

        footerCell.onTapLogo = { [weak self] in
            self?.delegate.didTapCompanyLink()
        }

        delegate.viewDidLoad()

        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    private var securityRows: [RowProtocol] {
        [
            StaticRow(
                    cell: manageAccountsCell,
                    id: "manage-accounts",
                    height: .heightSingleLineCell,
                    action: { [weak self] in
                        self?.delegate.onManageAccounts()
                    }
            ),
            StaticRow(
                    cell: securityCenterCell,
                    id: "security-center",
                    height: .heightSingleLineCell,
                    action: { [weak self] in
                        self?.delegate.didTapSecurity()
                    }
            )
        ]
    }

    private var walletConnectRows: [RowProtocol] {
        [
            StaticRow(
                    cell: walletConnectCell,
                    id: "wallet-connect",
                    height: .heightSingleLineCell,
                    autoDeselect: true,
                    action: { [weak self] in
                        WalletConnectModule.start(sourceViewController: self)
                    }
            )
        ]
    }

    private var appearanceRows: [RowProtocol] {
        [
            Row<A1Cell>(
                    id: "notifications",
                    height: .heightSingleLineCell,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence)
                        cell.titleImage = UIImage(named: "notification_20")
                        cell.title = "settings.notifications".localized
                    },
                    action: { [weak self] _ in
                        self?.delegate.didTapNotifications()
                    }
            ),
            StaticRow(
                    cell: baseCurrencyCell,
                    id: "base-currency",
                    height: .heightSingleLineCell,
                    action: { [weak self] in
                        self?.delegate.didTapBaseCurrency()
                    }
            ),
            StaticRow(
                    cell: languageCell,
                    id: "language",
                    height: .heightSingleLineCell,
                    action: { [weak self] in
                        self?.delegate.didTapLanguage()
                    }
            ),
            StaticRow(
                    cell: lightModeCell,
                    id: "light-mode",
                    height: .heightSingleLineCell
            ),
            Row<A1Cell>(
                    id: "experimental-features",
                    height: .heightSingleLineCell,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, bottomSeparator: true)
                        cell.titleImage = UIImage(named: "experimental_features_20")
                        cell.title = "settings.experimental_features".localized
                    },
                    action: { [weak self] _ in
                        self?.delegate.didTapExperimentalFeatures()
                    }
            )
        ]
    }

    private var knowledgeRows: [RowProtocol] {
        [
            Row<A1Cell>(
                    id: "faq",
                    height: .heightSingleLineCell,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence)
                        cell.titleImage = UIImage(named: "contact_20")
                        cell.title = "settings.faq".localized
                    },
                    action: { [weak self] _ in
                        self?.navigationController?.pushViewController(FaqModule.viewController(), animated: true)
                    }
            ),
            Row<A1Cell>(
                    id: "academy",
                    height: .heightSingleLineCell,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, bottomSeparator: true)
                        cell.titleImage = UIImage(named: "academy_20")
                        cell.title = "guides.title".localized
                    },
                    action: { [weak self] _ in
                        self?.navigationController?.pushViewController(GuidesModule.instance(), animated: true)
                    }
            )
        ]
    }

    private var contactRows: [RowProtocol] {
        [
            Row<A1Cell>(
                    id: "telegram",
                    height: .heightSingleLineCell,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence)
                        cell.titleImage = UIImage(named: "telegram_20")
                        cell.title = "Telegram"
                    },
                    action: { [weak self] _ in
                    }
            ),
            Row<A1Cell>(
                    id: "twitter",
                    height: .heightSingleLineCell,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence)
                        cell.titleImage = UIImage(named: "twitter_20")
                        cell.title = "Twitter"
                    },
                    action: { [weak self] _ in
                    }
            ),
            Row<A1Cell>(
                    id: "reddit",
                    height: .heightSingleLineCell,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, bottomSeparator: true)
                        cell.titleImage = UIImage(named: "reddit_20")
                        cell.title = "Reddit"
                    },
                    action: { [weak self] _ in
                    }
            )
        ]
    }

    private var aboutRows: [RowProtocol] {
        [
            StaticRow(
                    cell: aboutCell,
                    id: "about",
                    height: .heightSingleLineCell,
                    action: { [weak self] in
                    }
            )
        ]
    }

    private var footerRows: [RowProtocol] {
        [
            StaticRow(
                    cell: footerCell,
                    id: "footer",
                    height: footerCell.cellHeight
            )
        ]
    }

}

extension MainSettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(id: "security_settings", headerState: .margin(height: .margin12), rows: securityRows),
            Section(id: "wallet_connect", headerState: .margin(height: .margin32), rows: walletConnectRows),
            Section(id: "appearance_settings", headerState: .margin(height: .margin32), rows: appearanceRows),
            Section(id: "knowledge", headerState: .margin(height: .margin32), rows: knowledgeRows),
            Section(id: "contact", headerState: .margin(height: .margin32), rows: contactRows),
            Section(id: "about", headerState: .margin(height: .margin32), rows: aboutRows),
            Section(id: "footer", headerState: .margin(height: .margin32), footerState: .margin(height: .margin32), rows: footerRows)
        ]
    }

}

extension MainSettingsViewController: IMainSettingsView {

    func refresh() {
        tableView.reload()
    }

    func set(allBackedUp: Bool) {
        manageAccountsCell.valueImage = allBackedUp ? nil : UIImage(named: "attention_20")?.tinted(with: .themeLucian)
    }

    func set(pinSet: Bool) {
        securityCenterCell.valueImage = pinSet ? nil : UIImage(named: "attention_20")?.tinted(with: .themeLucian)
    }

    func set(termsAccepted: Bool) {
        aboutCell.valueImage = termsAccepted ? nil : UIImage(named: "attention_20")?.tinted(with: .themeLucian)
    }

    func set(currentWalletConnectPeer: String?) {
        walletConnectCell.value = currentWalletConnectPeer
    }

    func set(currentBaseCurrency: String) {
        baseCurrencyCell.value = currentBaseCurrency
    }

    func set(currentLanguage: String?) {
        languageCell.value = currentLanguage
    }

    func set(lightMode: Bool) {
        lightModeCell.isOn = lightMode
    }

    func set(appVersion: String) {
        footerCell.set(appVersion: appVersion)
    }

}

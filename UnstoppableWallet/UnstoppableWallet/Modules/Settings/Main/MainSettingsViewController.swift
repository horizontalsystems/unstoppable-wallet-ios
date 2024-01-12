import ComponentKit
import MessageUI
import ModuleKit
import RxCocoa
import RxSwift
import SafariServices
import SectionsTableView
import SnapKit
import ThemeKit
import UIExtensions
import UIKit

class MainSettingsViewController: ThemeViewController {
    private let viewModel: MainSettingsViewModel
    private var urlManager: UrlManager

    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let manageAccountsCell = BaseSelectableThemeCell()
    private let walletConnectCell = BaseSelectableThemeCell()
    private let securityCell = BaseSelectableThemeCell()
    private let appearanceCell = BaseSelectableThemeCell()
    private let contactBookCell = BaseSelectableThemeCell()
    private let baseCurrencyCell = BaseSelectableThemeCell()
    private let languageCell = BaseSelectableThemeCell()
    private let themeModeCell = BaseSelectableThemeCell()
    private let aboutCell = BaseSelectableThemeCell()
    private let footerCell = MainSettingsFooterCell()

    private let showTestNetSwitcher: Bool

    init(viewModel: MainSettingsViewModel, urlManager: UrlManager) {
        self.viewModel = viewModel
        self.urlManager = urlManager

        showTestNetSwitcher = Bundle.main.object(forInfoDictionaryKey: "ShowTestNetSwitcher") as? String == "true"

        super.init()

        tabBarItem = UITabBarItem(title: "settings.tab_bar_item".localized, image: UIImage(named: "filled_settings_2_24"), tag: 0)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings.title".localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        manageAccountsCell.set(backgroundStyle: .lawrence, isFirst: true)
        syncManageAccountCell()

        walletConnectCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        syncWalletConnectCell()

        securityCell.set(backgroundStyle: .lawrence, isFirst: true)
        syncSecurityCell()

        appearanceCell.set(backgroundStyle: .lawrence)
        buildTitleValue(cell: appearanceCell, image: UIImage(named: "brush_24"), title: "appearance.title".localized)

        contactBookCell.set(backgroundStyle: .lawrence)
        syncContactBookCell()

        baseCurrencyCell.set(backgroundStyle: .lawrence)
        syncBaseCurrency()

        languageCell.set(backgroundStyle: .lawrence, isLast: true)
        buildTitleValue(cell: languageCell, image: UIImage(named: "globe_24"), title: "settings.language".localized, value: viewModel.currentLanguage)

        aboutCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        syncAboutCell()

        footerCell.set(appVersion: viewModel.appVersion)
        footerCell.onTapLogo = { [weak self] in
            self?.viewModel.onTapCompanyLink()
        }

        subscribe(disposeBag, viewModel.manageWalletsAlertDriver) { [weak self] in self?.syncManageAccountCell(alert: $0) }
        subscribe(disposeBag, viewModel.securityCenterAlertDriver) { [weak self] in self?.syncSecurityCell(alert: $0) }
        subscribe(disposeBag, viewModel.iCloudSyncAlertDriver) { [weak self] in self?.syncContactBookCell(alert: $0) }

        subscribe(disposeBag, viewModel.walletConnectCountDriver) { [weak self] tuple in
            self?.syncWalletConnectCell(text: tuple?.text, highlighted: tuple?.highlighted ?? false)
        }
        subscribe(disposeBag, viewModel.baseCurrencyDriver) { [weak self] in self?.syncBaseCurrency(value: $0) }
        subscribe(disposeBag, viewModel.aboutAlertDriver) { [weak self] in self?.syncAboutCell(alert: $0) }

        subscribe(disposeBag, viewModel.openWalletConnectSignal) { [weak self] in self?.openWalletConnect(mode: $0) }
        subscribe(disposeBag, viewModel.openLinkSignal) { [weak self] url in
            self?.urlManager.open(url: url, from: self)
        }

        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    private func syncManageAccountCell(alert: Bool = false) {
        let alertImage = alert ? UIImage(named: "warning_2_20")?.withRenderingMode(.alwaysTemplate) : nil
        buildTitleImage(cell: manageAccountsCell, image: UIImage(named: "wallet_24"), title: "settings.manage_accounts".localized, alertImage: alertImage)
    }

    private func syncSecurityCell(alert: Bool = false) {
        let alertImage = alert ? UIImage(named: "warning_2_20")?.withRenderingMode(.alwaysTemplate) : nil
        buildTitleImage(cell: securityCell, image: UIImage(named: "shield_24"), title: "settings.security".localized, alertImage: alertImage)
    }

    private func syncContactBookCell(alert: Bool = false) {
        let alertImage = alert ? UIImage(named: "warning_2_20")?.withRenderingMode(.alwaysTemplate) : nil
        buildTitleImage(cell: contactBookCell, image: UIImage(named: "user_24"), title: "contacts.title".localized, alertImage: alertImage)
    }

    private func syncAboutCell(alert: Bool = false) {
        let alertImage = alert ? UIImage(named: "warning_2_20")?.withRenderingMode(.alwaysTemplate) : nil
        buildTitleImage(cell: aboutCell, image: UIImage(named: "uw_24"), title: "settings.about_app.title".localized, alertImage: alertImage)
    }

    private func buildTitleImage(cell: BaseThemeCell, image: UIImage?, title: String, alertImage: UIImage? = nil) {
        CellBuilderNew.buildStatic(cell: cell, rootElement: .hStack([
            .image24 { (component: ImageComponent) in
                component.imageView.image = image
            },
            .text { (component: TextComponent) in
                component.font = .body
                component.textColor = .themeLeah
                component.text = title
            },
            .image20 { (component: ImageComponent) in
                component.isHidden = alertImage == nil
                component.imageView.image = alertImage
                component.imageView.tintColor = .themeLucian
            },
            .margin8,
            .image20 { (component: ImageComponent) in
                component.imageView.image = UIImage(named: "arrow_big_forward_20")
            },
        ]))
    }

    private func syncWalletConnectCell(text: String? = nil, highlighted: Bool = false) {
        buildTitleValue(
            cell: walletConnectCell,
            image: UIImage(named: "wallet_connect_24"),
            title: "wallet_connect.title".localized,
            value: !highlighted ? text : nil,
            badge: highlighted ? text : nil
        )
    }

    private func syncBaseCurrency(value: String? = nil) {
        buildTitleValue(cell: baseCurrencyCell, image: UIImage(named: "usd_24"), title: "settings.base_currency".localized, value: value)
    }

    private func buildTitleValue(cell: BaseThemeCell, image: UIImage?, title: String, value: String? = nil, badge: String? = nil) {
        CellBuilderNew.buildStatic(cell: cell, rootElement: .hStack([
            .image24 { (component: ImageComponent) in
                component.imageView.image = image
            },
            .text { (component: TextComponent) in
                component.font = .body
                component.textColor = .themeLeah
                component.text = title
            },
            .text { (component: TextComponent) in
                component.font = .subhead1
                component.textColor = .themeGray
                component.text = value
            },
            .margin8,
            .badge { (component: BadgeComponent) in
                component.badgeView.set(style: .medium)
                component.isHidden = badge == nil
                component.badgeView.text = badge
            },
            .margin8,
            .image20 { (component: ImageComponent) in
                component.imageView.image = UIImage(named: "arrow_big_forward_20")
            },
        ]))
    }

    @objc private func onDonateTapped() {
        guard let viewController = WalletModule.donateTokenListViewController() else {
            return
        }
        present(viewController, animated: true)
    }

    private var accountRows: [RowProtocol] {
        [
            StaticRow(
                cell: manageAccountsCell,
                id: "manage-accounts",
                height: .heightCell48,
                action: { [weak self] in
                    self?.navigationController?.pushViewController(ManageAccountsModule.viewController(mode: .manage), animated: true)
                }
            ),
            tableView.universalRow48(
                id: "blockchain-settings",
                image: .local(UIImage(named: "blocks_24")),
                title: .body("settings.blockchain_settings".localized),
                accessoryType: .disclosure,
                isLast: false,
                action: { [weak self] in
                    let viewController = BlockchainSettingsModule.view().toViewController(title: "blockchain_settings.title".localized)
                    self?.navigationController?.pushViewController(viewController, animated: true)
                }
            ),
            tableView.universalRow48(
                id: "backup-manager",
                image: .local(UIImage(named: "icloud_24")),
                title: .body("settings.backup_manager".localized),
                accessoryType: .disclosure,
                isLast: true,
                action: { [weak self] in
                    let viewController = BackupManagerModule.viewController()
                    self?.navigationController?.pushViewController(viewController, animated: true)
                }
            ),
        ]
    }

    private var walletConnectRows: [RowProtocol] {
        [
            StaticRow(
                cell: walletConnectCell,
                id: "wallet-connect",
                height: .heightCell48,
                autoDeselect: true,
                action: { [weak self] in
                    self?.viewModel.onTapWalletConnect()
                }
            ),
        ]
    }

    private var appearanceRows: [RowProtocol] {
        [
            StaticRow(
                cell: securityCell,
                id: "security",
                height: .heightCell48,
                action: { [weak self] in
                    let viewController = SecuritySettingsModule.view().toViewController(title: "settings_security.title".localized)
                    self?.navigationController?.pushViewController(viewController, animated: true)
                }
            ),
            StaticRow(
                cell: contactBookCell,
                id: "address-book",
                height: .heightCell48,
                action: { [weak self] in
                    guard let viewController = ContactBookModule.viewController(mode: .edit) else {
                        return
                    }
                    self?.navigationController?.pushViewController(viewController, animated: true)
                }
            ),
            StaticRow(
                cell: appearanceCell,
                id: "launch-screen",
                height: .heightCell48,
                action: { [weak self] in
                    let viewController = AppearanceView().toViewController(title: "appearance.title".localized)
                    self?.navigationController?.pushViewController(viewController, animated: true)
                }
            ),
            StaticRow(
                cell: baseCurrencyCell,
                id: "base-currency",
                height: .heightCell48,
                action: { [weak self] in
                    self?.navigationController?.pushViewController(BaseCurrencySettingsModule.view().toViewController(title: "settings.base_currency.title".localized), animated: true)
                }
            ),
            StaticRow(
                cell: languageCell,
                id: "language",
                height: .heightCell48,
                action: { [weak self] in
                    let module = LanguageSettingsModule.view().toViewController(title: "settings.language".localized)
                    self?.navigationController?.pushViewController(module, animated: true)
                }
            ),
        ]
    }

    private var experimentalRows: [RowProtocol] {
        [
            tableView.universalRow48(
                id: "experimental-features",
                image: .local(UIImage(named: "flask_24")),
                title: .body("settings.experimental_features".localized),
                accessoryType: .disclosure,
                isFirst: true,
                isLast: true,
                action: { [weak self] in
                    let viewController = ExperimentalFeaturesView().toViewController(title: "settings.experimental_features.title".localized)
                    self?.navigationController?.pushViewController(viewController, animated: true)
                }
            ),
        ]
    }

    private var knowledgeRows: [RowProtocol] {
        [
            tableView.universalRow48(
                id: "faq",
                image: .local(UIImage(named: "message_square_24")),
                title: .body("settings.faq".localized),
                accessoryType: .disclosure,
                isFirst: true,
                action: { [weak self] in
                    self?.navigationController?.pushViewController(FaqModule.viewController(), animated: true)
                }
            ),
            tableView.universalRow48(
                id: "academy",
                image: .local(UIImage(named: "academy_1_24")),
                title: .body("guides.title".localized),
                accessoryType: .disclosure,
                isLast: true,
                action: { [weak self] in
                    self?.navigationController?.pushViewController(GuidesModule.instance(), animated: true)
                }
            ),
        ]
    }

    private var aboutRows: [RowProtocol] {
        [
            StaticRow(
                cell: aboutCell,
                id: "about",
                height: .heightCell48,
                action: { [weak self] in
                    self?.navigationController?.pushViewController(AboutModule.view().toViewController(title: "settings.about_app.title".localized), animated: true)
                }
            ),
        ]
    }

    private var feedbackRows: [RowProtocol] {
        [
            tableView.universalRow48(
                id: "rate-us",
                image: .local(UIImage(named: "rate_24")),
                title: .body("settings.rate_us".localized),
                accessoryType: .disclosure,
                autoDeselect: true,
                isFirst: true,
                action: { [weak self] in
                    self?.viewModel.onTapRateApp()
                }
            ),
            tableView.universalRow48(
                id: "tell-friends",
                image: .local(UIImage(named: "share_1_24")),
                title: .body("settings.tell_friends".localized),
                accessoryType: .disclosure,
                autoDeselect: true,
                action: { [weak self] in
                    self?.openTellFriends()
                }
            ),
            tableView.universalRow48(
                id: "contact-us",
                image: .local(UIImage(named: "mail_24")),
                title: .body("settings.contact_us".localized),
                accessoryType: .disclosure,
                autoDeselect: true,
                isLast: true,
                action: { [weak self] in
                    self?.handleContact()
                }
            ),
        ]
    }

    private var donateRows: [RowProtocol] {
        [
            tableView.universalRow48(
                id: "donate",
                image: .local(UIImage(named: "heart_fill_24")?.withTintColor(.themeJacob)),
                title: .body("settings.donate.title".localized),
                accessoryType: .disclosure,
                autoDeselect: true,
                isFirst: true,
                isLast: true,
                action: { [weak self] in self?.onDonateTapped() }
            ),
        ]
    }

    private var footerRows: [RowProtocol] {
        [
            StaticRow(
                cell: footerCell,
                id: "footer",
                height: footerCell.cellHeight
            ),
        ]
    }

    private func openWalletConnect(mode: MainSettingsViewModel.WalletConnectOpenMode) {
        switch mode {
        case let .errorDialog(error):
            WalletConnectAppShowView.showWalletConnectError(error: error, sourceViewController: self)
        case .list:
            navigationController?.pushViewController(WalletConnectListModule.viewController(), animated: true)
        }
    }

    private func openTellFriends() {
        let text = "settings_tell_friends.text".localized + "\n" + AppConfig.appWebPageLink
        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: [])
        present(activityViewController, animated: true, completion: nil)
    }

    private func handleEmailContact() {
        let email = AppConfig.reportEmail

        if MFMailComposeViewController.canSendMail() {
            let controller = MFMailComposeViewController()
            controller.setToRecipients([email])
            controller.mailComposeDelegate = self

            present(controller, animated: true)
        } else {
            CopyHelper.copyAndNotify(value: email)
        }
    }

    private func handleTelegramContact() {
        navigationController?.pushViewController(PersonalSupportModule.viewController(), animated: true)
    }

    private func handleContact() {
        let viewController = BottomSheetModule.viewController(
            image: .local(name: "at_24", tint: .warning),
            title: "settings.contact.title".localized,
            items: [],
            buttons: [
                .init(style: .yellow, title: "settings.contact.via_email".localized, actionType: .afterClose) { [weak self] in
                    self?.handleEmailContact()
                },
                .init(style: .gray, title: "settings.contact.via_telegram".localized, actionType: .afterClose) { [weak self] in
                    self?.handleTelegramContact()
                },
            ]
        )

        present(viewController, animated: true)
    }
}

extension MainSettingsViewController: SectionsDataSource {
    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(id: "account", headerState: .margin(height: AppConfig.donateEnabled ? .margin32 : .margin12), rows: accountRows),
            Section(id: "wallet_connect", headerState: .margin(height: .margin32), rows: walletConnectRows),
            Section(id: "appearance_settings", headerState: .margin(height: .margin32), rows: appearanceRows),
            Section(id: "knowledge", headerState: .margin(height: .margin32), rows: knowledgeRows),
            Section(id: "about", headerState: .margin(height: .margin32), rows: aboutRows),
            Section(id: "experimental", headerState: .margin(height: .margin32), rows: experimentalRows),
            Section(id: "feedback", headerState: .margin(height: .margin32), rows: feedbackRows),
            Section(id: "footer", headerState: .margin(height: .margin32), footerState: .margin(height: .margin32), rows: footerRows),
        ]

        if AppConfig.donateEnabled {
            sections.insert(Section(id: "donate", headerState: .margin(height: .margin12), rows: donateRows), at: 0)
        }

        if showTestNetSwitcher {
            sections.append(
                Section(
                    id: "test-net-switcher",
                    footerState: .margin(height: .margin32),
                    rows: [
                        tableView.universalRow48(
                            id: "test-net-switcher",
                            title: .body("TestNet Enabled"),
                            accessoryType: .switch(
                                isOn: App.shared.testNetManager.testNetEnabled,
                                onSwitch: { enabled in
                                    App.shared.testNetManager.set(testNetEnabled: enabled)
                                }
                            ),
                            isFirst: true,
                            isLast: true
                        ),
                    ]
                )
            )
        }

        return sections
    }
}

extension MainSettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith _: MFMailComposeResult, error _: Error?) {
        controller.dismiss(animated: true)
    }
}

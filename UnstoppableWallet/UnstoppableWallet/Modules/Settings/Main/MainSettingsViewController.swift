import ComponentKit
import MessageUI
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

    private let premiumCell = MainSettingsPremiumCell()
    private let manageAccountsCell = BaseSelectableThemeCell()
    private let walletConnectCell = BaseSelectableThemeCell()
    private let tonConnectCell = BaseSelectableThemeCell()
    private let securityCell = BaseSelectableThemeCell()
    private let privacyCell = BaseSelectableThemeCell()
    private let appearanceCell = BaseSelectableThemeCell()
    private let subscriptionCell = BaseSelectableThemeCell()
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
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)

        tableView.registerHeaderFooter(forClass: HighlightedSubtitleHeaderFooterView.self)
        tableView.registerCell(forClass: MainSettingsPremiumCell.self)
        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        syncPremiumCell(tryForFree: viewModel.allowFreeTrial)

        manageAccountsCell.set(backgroundStyle: .lawrence, isFirst: true)
        syncManageAccountCell()

        walletConnectCell.set(backgroundStyle: .lawrence)
        syncWalletConnectCell()

        tonConnectCell.set(backgroundStyle: .lawrence)
        syncTonConnectCell()

        securityCell.set(backgroundStyle: .lawrence, isFirst: true)
        syncSecurityCell()

        privacyCell.set(backgroundStyle: .lawrence)
        buildTitleValue(cell: privacyCell, image: UIImage(named: "eye_2_24"), title: "settings.privacy".localized)

        appearanceCell.set(backgroundStyle: .lawrence)
        buildTitleValue(cell: appearanceCell, image: UIImage(named: "brush_24"), title: "appearance.title".localized)

        subscriptionCell.set(backgroundStyle: .lawrence)
        buildTitleValue(cell: subscriptionCell, image: UIImage(named: "star_24"), title: "subscription.title".localized)

        contactBookCell.set(backgroundStyle: .lawrence)
        syncContactBookCell()

        baseCurrencyCell.set(backgroundStyle: .lawrence)
        syncBaseCurrency()

        languageCell.set(backgroundStyle: .lawrence, isLast: true)
        buildTitleValue(cell: languageCell, image: UIImage(named: "globe_24"), title: "settings.language".localized, value: viewModel.currentLanguage)

        aboutCell.set(backgroundStyle: .lawrence, isFirst: true)
        syncAboutCell()

        footerCell.set(appVersion: viewModel.appVersion)
        footerCell.onTapLogo = { [weak self] in
            self?.viewModel.onTapCompanyLink()

            stat(page: .settings, event: .open(page: .externalCompanyWebsite))
        }

        subscribe(disposeBag, viewModel.allowFreeTrialSignal) { [weak self] in self?.syncPremiumCell(tryForFree: $0) }
        subscribe(disposeBag, viewModel.manageWalletsAlertDriver) { [weak self] in self?.syncManageAccountCell(alert: $0) }
        subscribe(disposeBag, viewModel.securityCenterAlertDriver) { [weak self] in self?.syncSecurityCell(alert: $0) }
        subscribe(disposeBag, viewModel.iCloudSyncAlertDriver) { [weak self] in self?.syncContactBookCell(alert: $0) }
        subscribe(disposeBag, viewModel.showSubscriptionDriver) { [weak self] in self?.sync(showSubscriptionCell: $0) }

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

    private func syncPremiumCell(tryForFree: Bool) {
        premiumCell.bind(tryForFree: tryForFree)
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

    private func syncTonConnectCell(text: String? = nil, highlighted: Bool = false) {
        buildTitleValue(
            cell: tonConnectCell,
            image: UIImage(named: "ton_connect_24"),
            title: "TON Connect",
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

        stat(page: .settings, event: .open(page: .donate))
    }

    private func onTokenTapped() {
        UrlManager.open(url: "https://t.me/\(AppConfig.appTokenTelegramAccount)")
    }

    private func sync(showSubscriptionCell _: Bool) {
        tableView.reload()
    }

    private func onSubscriptionTapped() {
        let viewController = PurchaseListView().toViewController(title: "subscription.title".localized)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private var accountRows: [RowProtocol] {
        [
            StaticRow(
                cell: manageAccountsCell,
                id: "manage-accounts",
                height: .heightCell48,
                action: { [weak self] in
                    self?.navigationController?.pushViewController(ManageAccountsModule.viewController(mode: .manage), animated: true)

                    stat(page: .settings, event: .open(page: .manageWallets))
                }
            ),
            tableView.universalRow48(
                id: "blockchain-settings",
                image: .local(UIImage(named: "blocks_24")),
                title: .body("settings.blockchain_settings".localized),
                accessoryType: .disclosure,
                action: { [weak self] in
                    let viewController = BlockchainSettingsModule.view().toViewController(title: "blockchain_settings.title".localized)
                    self?.navigationController?.pushViewController(viewController, animated: true)

                    stat(page: .settings, event: .open(page: .blockchainSettings))
                }
            ),
            StaticRow(
                cell: walletConnectCell,
                id: "wallet-connect",
                height: .heightCell48,
                autoDeselect: true,
                action: { [weak self] in
                    self?.viewModel.onTapWalletConnect()
                }
            ),
            // StaticRow(
            //     cell: tonConnectCell,
            //     id: "ton-connect",
            //     height: .heightCell48,
            //     autoDeselect: true,
            //     action: { [weak self] in
            //         self?.onTapTonConnect()
            //     }
            // ),
            tableView.universalRow48(
                id: "backup-manager",
                image: .local(UIImage(named: "icloud_24")),
                title: .body("settings.backup_manager".localized),
                accessoryType: .disclosure,
                isFirst: false,
                isLast: true,
                action: { [weak self] in
                    let viewController = BackupManagerModule.viewController()
                    self?.navigationController?.pushViewController(viewController, animated: true)

                    stat(page: .settings, event: .open(page: .backupManager))
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

                    stat(page: .settings, event: .open(page: .security))
                }
            ),
            StaticRow(
                cell: privacyCell,
                id: "privacy",
                height: .heightCell48,
                action: { [weak self] in
                    let viewController = PrivacyPolicyView(config: .privacy).toViewController(title: "settings.privacy".localized)

                    self?.navigationController?.pushViewController(viewController, animated: true)
                    stat(page: .settings, event: .open(page: .privacy))
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

                    stat(page: .settings, event: .open(page: .contacts))
                }
            ),
            StaticRow(
                cell: appearanceCell,
                id: "launch-screen",
                height: .heightCell48,
                action: { [weak self] in
                    let viewController = AppearanceView().toViewController(title: "appearance.title".localized)
                    self?.navigationController?.pushViewController(viewController, animated: true)

                    stat(page: .settings, event: .open(page: .appearance))
                }
            ),
            StaticRow(
                cell: subscriptionCell,
                id: "subscription",
                height: .heightCell48,
                autoDeselect: true,
                action: { [weak self] in
                    self?.onSubscriptionTapped()
                }
            ),
            StaticRow(
                cell: baseCurrencyCell,
                id: "base-currency",
                height: .heightCell48,
                action: { [weak self] in
                    self?.navigationController?.pushViewController(BaseCurrencySettingsModule.view().toViewController(title: "settings.base_currency.title".localized), animated: true)

                    stat(page: .settings, event: .open(page: .baseCurrency))
                }
            ),
            StaticRow(
                cell: languageCell,
                id: "language",
                height: .heightCell48,
                action: { [weak self] in
                    let module = LanguageSettingsModule.view().toViewController(title: "settings.language".localized)
                    self?.navigationController?.pushViewController(module, animated: true)

                    stat(page: .settings, event: .open(page: .language))
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

                    stat(page: .settings, event: .open(page: .faq))
                }
            ),
            tableView.universalRow48(
                id: "education",
                image: .local(UIImage(named: "academy_1_24")),
                title: .body("education.title".localized),
                accessoryType: .disclosure,
                isLast: true,
                action: { [weak self] in
                    self?.navigationController?.pushViewController(EducationView().toViewController(title: "education.title".localized), animated: true)

                    stat(page: .settings, event: .open(page: .education))
                }
            ),
        ]
    }

    private func openVipSupport() {
        guard viewModel.activated(.vipSupport) else {
            present(PurchasesView().toViewController(), animated: true)
            return
        }

        let viewController = SupportView { telegramUrl in
            UrlManager.open(url: telegramUrl)
        }.toViewController().toBottomSheet

        present(viewController, animated: true)
        stat(page: .settings, event: .open(page: .vipSupport))
    }

    private var premiumSupportRows: [RowProtocol] {
        [
            tableView.universalRow48(
                id: "support",
                image: .local(UIImage(named: "support_2_24")?.withTintColor(.themeJacob)),
                title: .body("purchases.vip_support".localized),
                accessoryType: .disclosure,
                backgroundStyle: .borderedLawrence(.themeJacob),
                autoDeselect: true,
                isFirst: true,
                isLast: true,
                action: { [weak self] in
                    self?.openVipSupport()
                }
            ),
        ]
    }

    private var socialRows: [RowProtocol] {
        [
            tableView.universalRow48(
                id: "telegram",
                image: .local(UIImage(named: "filled_telegram_24")),
                title: .body("Telegram"),
                accessoryType: .disclosure,
                autoDeselect: true,
                isFirst: true,
                action: {
                    UrlManager.open(url: "https://t.me/\(AppConfig.appTelegramAccount)")

                    stat(page: .settings, event: .open(page: .externalTelegram))
                }
            ),
            tableView.universalRow48(
                id: "twitter",
                image: .local(UIImage(named: "filled_twitter_24")),
                title: .body("Twitter"),
                accessoryType: .disclosure,
                autoDeselect: true,
                isLast: true,
                action: {
                    let account = AppConfig.appTwitterAccount

                    if let appUrl = URL(string: "twitter://user?screen_name=\(account)"), UIApplication.shared.canOpenURL(appUrl) {
                        UIApplication.shared.open(appUrl)
                    } else {
                        UrlManager.open(url: "https://twitter.com/\(account)")
                    }

                    stat(page: .settings, event: .open(page: .externalTwitter))
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

                    stat(page: .settings, event: .open(page: .aboutApp))
                }
            ),
            tableView.universalRow48(
                id: "rate-us",
                image: .local(UIImage(named: "rate_24")),
                title: .body("settings.rate_us".localized),
                accessoryType: .disclosure,
                autoDeselect: true,
                action: { [weak self] in
                    self?.viewModel.onTapRateApp()

                    stat(page: .settings, event: .open(page: .rateUs))
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
        ]
    }

    private var donateRows: [RowProtocol] {
        [
            tableView.universalRow48(
                id: "donate",
                image: .local(UIImage(named: "heart_24")?.withTintColor(.themeGray)),
                title: .body("settings.donate.title".localized),
                accessoryType: .disclosure,
                autoDeselect: true,
                isFirst: true,
                isLast: true,
                action: { [weak self] in
                    self?.onDonateTapped()
                }
            ),
        ]
    }

    private var premiumRows: [RowProtocol] {
        [
            StaticRow(
                cell: premiumCell,
                id: "premium",
                height: MainSettingsPremiumCell.height,
                action: { [weak self] in
                    self?.present(PurchasesView().toViewController(), animated: true)
                }
            ),
        ]
    }

    private var tokenRows: [RowProtocol] {
        [
            tableView.universalRow48(
                id: "token",
                image: .local(UIImage(named: "uwt_24")?.withTintColor(.themeJacob)),
                title: .body("settings.get_your_tokens".localized),
                accessoryType: .disclosure,
                autoDeselect: true,
                isFirst: true,
                isLast: true,
                action: { [weak self] in
                    self?.onTokenTapped()
                }
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

        stat(page: .settings, event: .open(page: .tellFriends))
    }

    private func onTapTonConnect() {
        navigationController?.pushViewController(TonConnectListView().toViewController(title: "TON Connect"), animated: true)
    }
}

extension MainSettingsViewController: SectionsDataSource {
    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(id: "token", headerState: .margin(height: .margin32), rows: tokenRows),
            Section(id: "account", headerState: .margin(height: .margin32), rows: accountRows),
            Section(id: "appearance_settings", headerState: .margin(height: .margin32), rows: appearanceRows),
            Section(
                id: "premium",
                headerState: .static(view: PremiumHeaderFooterView(), height: .margin32 + .margin24),
                rows: premiumSupportRows
            ),
            Section(id: "about", headerState: .margin(height: .margin32), footerState: .margin(height: .margin32), rows: aboutRows),
            Section(
                id: "social",
                headerState: .cellType(
                    hash: "settings.social_networks.label".localized,
                    binder: { (view: HighlightedSubtitleHeaderFooterView) in
                        view.bind(text: "settings.social_networks.label".localized, color: .themeGray, backgroundColor: UIColor.clear)
                    },
                    dynamicHeight: { _ in .margin32 }
                ),
                rows: socialRows
            ),
            Section(id: "knowledge", headerState: .margin(height: .margin32), rows: knowledgeRows),
        ]

        if AppConfig.donateEnabled {
            sections.append(Section(id: "donate", headerState: .margin(height: .margin32), rows: donateRows))
        }

        sections.append(Section(id: "footer", headerState: .margin(height: .margin32), footerState: .margin(height: .margin32), rows: footerRows))

        if !viewModel.hasActiveSubscriptions {
            sections.insert(Section(id: "premium", headerState: .margin(height: .margin12), rows: premiumRows), at: 0)
        }

        if showTestNetSwitcher {
            sections.append(
                Section(
                    id: "test-net-switcher",
                    footerState: .margin(height: .margin32),
                    rows: [
                        tableView.universalRow48(
                            id: "new-send-switcher",
                            title: .body("New Send"),
                            accessoryType: .switch(
                                isOn: App.shared.localStorage.newSendEnabled,
                                onSwitch: { enabled in
                                    App.shared.localStorage.newSendEnabled = enabled
                                }
                            ),
                            isFirst: true
                        ),
                        tableView.universalRow48(
                            id: "test-net-switcher",
                            title: .body("TestNet Enabled"),
                            accessoryType: .switch(
                                isOn: App.shared.testNetManager.testNetEnabled,
                                onSwitch: { enabled in
                                    App.shared.testNetManager.set(testNetEnabled: enabled)
                                }
                            ),
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

class HighlightedSubtitleHeaderFooterView: UITableViewHeaderFooterView {
    private let label = UILabel()

    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundView = UIView()

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin32)
            maker.centerY.equalToSuperview()
        }

        label.font = .subhead1
        label.textColor = .themeGray
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String?, color: UIColor = .clear, backgroundColor: UIColor = .clear) {
        label.text = text?.uppercased()
        label.textColor = color
        backgroundView?.backgroundColor = backgroundColor
    }
}

class PremiumHeaderFooterView: UITableViewHeaderFooterView {
    private let iconView = UIImageView()
    private let label = UILabel()

    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundView = UIView()

        addSubview(iconView)
        iconView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin32)
            maker.bottom.equalToSuperview().inset(9)
            maker.size.equalTo(CGFloat.iconSize16)
        }

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.equalTo(iconView.snp.trailing).offset(CGFloat.margin6)
            maker.trailing.equalToSuperview().inset(CGFloat.margin32)
            maker.bottom.equalToSuperview().inset(9)
        }

        label.font = .subhead1

        bind()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(iconName: String = "star_filled_16", text: String? = "subscription.premium.label".localized, color: UIColor = .themeJacob, backgroundColor: UIColor = .clear) {
        label.text = text
        label.textColor = color

        iconView.image = UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = color

        backgroundView?.backgroundColor = backgroundColor
    }
}

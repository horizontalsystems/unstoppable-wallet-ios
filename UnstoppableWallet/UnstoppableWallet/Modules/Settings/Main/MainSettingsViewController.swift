import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import UIExtensions
import ModuleKit
import RxSwift
import RxCocoa
import SafariServices
import ComponentKit

class MainSettingsViewController: ThemeViewController {
    private let viewModel: MainSettingsViewModel
    private var urlManager: IUrlManager

    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let manageAccountsCell = A3Cell()
    private let securityCenterCell = A3Cell()
    private let walletConnectCell = A2Cell()
    private let baseCurrencyCell = A2Cell()
    private let languageCell = A2Cell()
    private let themeModeCell = A2Cell()
    private let aboutCell = A3Cell()
    private let footerCell = MainSettingsFooterCell()

    init(viewModel: MainSettingsViewModel, urlManager: IUrlManager) {
        self.viewModel = viewModel
        self.urlManager = urlManager

        super.init()

        tabBarItem = UITabBarItem(title: "settings.tab_bar_item".localized, image: UIImage(named: "filled_settings_2_24"), tag: 0)
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

        manageAccountsCell.set(backgroundStyle: .lawrence, isFirst: true)
        manageAccountsCell.titleImage = UIImage(named: "wallet_20")
        manageAccountsCell.title = "settings.manage_accounts".localized

        securityCenterCell.set(backgroundStyle: .lawrence, isLast: true)
        securityCenterCell.titleImage = UIImage(named: "shield_20")
        securityCenterCell.title = "settings.security_center".localized

        walletConnectCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        walletConnectCell.titleImage = UIImage(named: "wallet_connect_20")
        walletConnectCell.title = "wallet_connect.title".localized

        baseCurrencyCell.set(backgroundStyle: .lawrence)
        baseCurrencyCell.titleImage = UIImage(named: "usd_20")
        baseCurrencyCell.title = "settings.base_currency".localized

        languageCell.set(backgroundStyle: .lawrence)
        languageCell.titleImage = UIImage(named: "globe_20")
        languageCell.title = "settings.language".localized
        languageCell.value = viewModel.currentLanguage

        themeModeCell.set(backgroundStyle: .lawrence)
        themeModeCell.titleImage = UIImage(named: "light_20")
        themeModeCell.title = "settings.theme".localized

        aboutCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        aboutCell.titleImage = UIImage(named: "uw_20")
        aboutCell.title = "settings.about_app.title".localized

        footerCell.set(appVersion: viewModel.appVersion)
        footerCell.onTapLogo = { [weak self] in
            self?.viewModel.onTapCompanyLink()
        }

        subscribe(disposeBag, viewModel.manageWalletsAlertDriver) { [weak self] alert in
            self?.manageAccountsCell.valueImage = alert ? UIImage(named: "warning_2_20")?.withRenderingMode(.alwaysTemplate) : nil
            self?.manageAccountsCell.valueImageTintColor = .themeLucian
        }
        subscribe(disposeBag, viewModel.securityCenterAlertDriver) { [weak self] alert in
            self?.securityCenterCell.valueImage = alert ? UIImage(named: "warning_2_20")?.withRenderingMode(.alwaysTemplate) : nil
            self?.securityCenterCell.valueImageTintColor = .themeLucian
        }
        subscribe(disposeBag, viewModel.walletConnectSessionCountDriver) { [weak self] count in
            self?.walletConnectCell.value = count
        }
        subscribe(disposeBag, viewModel.baseCurrencyDriver) { [weak self] baseCurrency in
            self?.baseCurrencyCell.value = baseCurrency
        }
        subscribe(disposeBag, viewModel.aboutAlertDriver) { [weak self] alert in
            self?.aboutCell.valueImage = alert ? UIImage(named: "warning_2_20")?.withRenderingMode(.alwaysTemplate) : nil
            self?.aboutCell.valueImageTintColor = .themeLucian
        }
        subscribe(disposeBag, viewModel.themeModeDriver) { [weak self] themeMode in
            self?.themeModeCell.value = themeMode.description
        }

        subscribe(disposeBag, viewModel.openLinkSignal) { [weak self] url in
            self?.urlManager.open(url: url, from: self)
        }

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
                    height: .heightCell48,
                    action: { [weak self] in
                        self?.navigationController?.pushViewController(ManageAccountsModule.viewController(mode: .manage), animated: true)
                    }
            ),
            StaticRow(
                    cell: securityCenterCell,
                    id: "security-center",
                    height: .heightCell48,
                    action: { [weak self] in
                        self?.navigationController?.pushViewController(SecuritySettingsRouter.module(), animated: true)
                    }
            )
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
                        self?.openWalletConnect()
                    }
            )
        ]
    }

    private var appearanceRows: [RowProtocol] {
        [
            Row<A1Cell>(
                    id: "notifications",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: true)
                        cell.titleImage = UIImage(named: "bell_ring_20")
                        cell.title = "settings.notifications".localized
                    },
                    action: { [weak self] _ in
                        self?.navigationController?.pushViewController(NotificationSettingsRouter.module(), animated: true)
                    }
            ),
            StaticRow(
                    cell: baseCurrencyCell,
                    id: "base-currency",
                    height: .heightCell48,
                    action: { [weak self] in
                        self?.navigationController?.pushViewController(BaseCurrencySettingsModule.viewController(), animated: true)
                    }
            ),
            StaticRow(
                    cell: languageCell,
                    id: "language",
                    height: .heightCell48,
                    action: { [weak self] in
                        let module = LanguageSettingsRouter.module { MainModule.instance(selectedTab: .settings) }
                        self?.navigationController?.pushViewController(module, animated: true)
                    }
            ),
            StaticRow(
                    cell: themeModeCell,
                    id: "theme-mode",
                    height: .heightCell48,
                    action: { [weak self] in
                        self?.navigationController?.pushViewController(ThemeSettingsModule.viewController(), animated: true)
                    }
            ),
            Row<A1Cell>(
                    id: "experimental-features",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isLast: true)
                        cell.titleImage = UIImage(named: "flask_20")
                        cell.title = "settings.experimental_features".localized
                    },
                    action: { [weak self] _ in
                        self?.navigationController?.pushViewController(ExperimentalFeaturesRouter.module(), animated: true)
                    }
            )
        ]
    }

    private var knowledgeRows: [RowProtocol] {
        [
            Row<A1Cell>(
                    id: "faq",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: true)
                        cell.titleImage = UIImage(named: "message_square_20")
                        cell.title = "settings.faq".localized
                    },
                    action: { [weak self] _ in
                        self?.navigationController?.pushViewController(FaqModule.viewController(), animated: true)
                    }
            ),
            Row<A1Cell>(
                    id: "academy",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isLast: true)
                        cell.titleImage = UIImage(named: "academy_1_20")
                        cell.title = "guides.title".localized
                    },
                    action: { [weak self] _ in
                        self?.navigationController?.pushViewController(GuidesModule.instance(), animated: true)
                    }
            )
        ]
    }

    private var aboutRows: [RowProtocol] {
        [
            StaticRow(
                    cell: aboutCell,
                    id: "about",
                    height: .heightCell48,
                    action: { [weak self] in
                        self?.navigationController?.pushViewController(AboutModule.viewController(), animated: true)
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

    private func openWalletConnect() {
        let walletConnectListViewController = WalletConnectListModule.viewController()

        switch viewModel.walletConnectOpenMode {
        case .sessionList:
            navigationController?.pushViewController(walletConnectListViewController, animated: true)
        case .qrScanner:
            navigationController?.pushViewController(walletConnectListViewController, animated: false)
            WalletConnectModule.start(sourceViewController: walletConnectListViewController)
        }
    }

}

extension MainSettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(id: "security_settings", headerState: .margin(height: .margin12), rows: securityRows),
            Section(id: "wallet_connect", headerState: .margin(height: .margin32), rows: walletConnectRows),
            Section(id: "appearance_settings", headerState: .margin(height: .margin32), rows: appearanceRows),
            Section(id: "knowledge", headerState: .margin(height: .margin32), rows: knowledgeRows),
            Section(id: "about", headerState: .margin(height: .margin32), rows: aboutRows),
            Section(id: "footer", headerState: .margin(height: .margin32), footerState: .margin(height: .margin32), rows: footerRows)
        ]
    }

}

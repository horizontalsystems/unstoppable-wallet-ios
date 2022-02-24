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

    private let manageAccountsCell = BaseSelectableThemeCell()
    private let securityCenterCell = BaseSelectableThemeCell()
    private let walletConnectCell = BaseSelectableThemeCell()
    private let launchScreenCell = BaseSelectableThemeCell()
    private let baseCurrencyCell = BaseSelectableThemeCell()
    private let languageCell = BaseSelectableThemeCell()
    private let themeModeCell = BaseSelectableThemeCell()
    private let aboutCell = BaseSelectableThemeCell()
    private let footerCell = MainSettingsFooterCell()

    private let titleStyle: TextComponent.Style = .b2

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
        buildTitleImage(cell: manageAccountsCell, image: UIImage(named: "wallet_20"), title: "settings.manage_accounts".localized)

        securityCenterCell.set(backgroundStyle: .lawrence, isLast: true)
        buildTitleImage(cell: securityCenterCell, image: UIImage(named: "shield_20"), title: "settings.security_center".localized)

        walletConnectCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        buildTitleValue(cell: walletConnectCell, image: UIImage(named: "wallet_connect_20"), title: "wallet_connect.title".localized)

        launchScreenCell.set(backgroundStyle: .lawrence, isFirst: true)
        buildTitleValue(cell: launchScreenCell, image: UIImage(named: "screen_20"), title: "settings.launch_screen.title".localized)

        baseCurrencyCell.set(backgroundStyle: .lawrence)
        buildTitleValue(cell: baseCurrencyCell, image: UIImage(named: "usd_20"), title: "settings.base_currency".localized)

        languageCell.set(backgroundStyle: .lawrence)
        buildTitleValue(cell: languageCell, image: UIImage(named: "globe_20"), title: "settings.language".localized)
        languageCell.bind(index: 2) { (component: TextComponent) in
            component.text = viewModel.currentLanguage
        }

        themeModeCell.set(backgroundStyle: .lawrence)
        buildTitleValue(cell: themeModeCell, image: UIImage(named: "light_20"), title: "settings.theme".localized)

        aboutCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        buildTitleImage(cell: aboutCell, image: UIImage(named: "uw_20"), title: "settings.about_app.title".localized)

        footerCell.set(appVersion: viewModel.appVersion)
        footerCell.onTapLogo = { [weak self] in
            self?.viewModel.onTapCompanyLink()
        }

        subscribe(disposeBag, viewModel.manageWalletsAlertDriver) { [weak self] alert in
            self?.manageAccountsCell.bind(index: 2) { (component: ImageComponent) in
                component.imageView.image = alert ? UIImage(named: "warning_2_20")?.withRenderingMode(.alwaysTemplate) : nil
                component.imageView.tintColor = .themeLucian
            }
        }
        subscribe(disposeBag, viewModel.securityCenterAlertDriver) { [weak self] alert in
            self?.securityCenterCell.bind(index: 2) { (component: ImageComponent) in
                component.imageView.image = alert ? UIImage(named: "warning_2_20")?.withRenderingMode(.alwaysTemplate) : nil
                component.imageView.tintColor = .themeLucian
            }
        }
        subscribe(disposeBag, viewModel.walletConnectSessionCountDriver) { [weak self] count in
            self?.walletConnectCell.bind(index: 2) { (component: TextComponent) in
                component.text = count
            }
        }
        subscribe(disposeBag, viewModel.launchScreenDriver) { [weak self] launchScreen in
            self?.launchScreenCell.bind(index: 2) { (component: TextComponent) in
                component.text = launchScreen
            }
        }
        subscribe(disposeBag, viewModel.baseCurrencyDriver) { [weak self] baseCurrency in
            self?.baseCurrencyCell.bind(index: 2) { (component: TextComponent) in
                component.text = baseCurrency
            }
        }
        subscribe(disposeBag, viewModel.themeModeDriver) { [weak self] themeMode in
            self?.themeModeCell.bind(index: 2) { (component: TextComponent) in
                component.text = themeMode.description
            }
        }
        subscribe(disposeBag, viewModel.aboutAlertDriver) { [weak self] alert in
            self?.aboutCell.bind(index: 2) { (component: ImageComponent) in
                component.imageView.image = alert ? UIImage(named: "warning_2_20")?.withRenderingMode(.alwaysTemplate) : nil
                component.imageView.tintColor = .themeLucian
            }
        }

        subscribe(disposeBag, viewModel.openWalletConnectSignal) { [weak self] in self?.openWalletConnect(mode: $0) }
        subscribe(disposeBag, viewModel.openLinkSignal) { [weak self] url in
            self?.urlManager.open(url: url, from: self)
        }

        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    private func buildTitleImage(cell: BaseThemeCell, image: UIImage?, title: String) {
        CellBuilder.build(cell: cell, elements: [.image20, .text, .image20, .margin8, .image20])
        cell.bind(index: 0) { (component: ImageComponent) in
            component.imageView.image = image
        }
        cell.bind(index: 1) { (component: TextComponent) in
            component.set(style: titleStyle)
            component.text = title
        }
        cell.bind(index: 3) { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "arrow_big_forward_20")
        }
    }

    private func buildTitleValue(cell: BaseThemeCell, image: UIImage?, title: String) {
        CellBuilder.build(cell: cell, elements: [.image20, .text, .text, .margin8, .image20])
        cell.bind(index: 0) { (component: ImageComponent) in
            component.imageView.image = image
        }
        cell.bind(index: 1) { (component: TextComponent) in
            component.set(style: titleStyle)
            component.text = title
        }
        cell.bind(index: 2) { (component: TextComponent) in
            component.set(style: .c1)
        }
        cell.bind(index: 3) { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "arrow_big_forward_20")
        }
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
                        self?.viewModel.onTapWalletConnect()
                    }
            )
        ]
    }

    private var appearanceRows: [RowProtocol] {
        [
            StaticRow(
                    cell: launchScreenCell,
                    id: "launch-screen",
                    height: .heightCell48,
                    action: { [weak self] in
                        self?.navigationController?.pushViewController(LaunchScreenModule.viewController(), animated: true)
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
                        let module = LanguageSettingsRouter.module { MainModule.instance(presetTab: .settings) }
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

    private func openWalletConnect(mode: MainSettingsViewModel.WalletConnectOpenMode) {
        switch mode {
        case .noAccount:
            present(WalletConnectNoAccountViewController().toBottomSheet, animated: true)
        case .watchAccount:
            present(WalletConnectWatchAccountViewController(sourceViewController: self).toBottomSheet, animated: true)
        case .list:
            navigationController?.pushViewController(WalletConnectListModule.viewController(), animated: true)
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

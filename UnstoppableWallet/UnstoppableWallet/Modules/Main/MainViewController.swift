import UIKit
import ThemeKit
import RxSwift
import RxCocoa
import StorageKit

class MainViewController: ThemeTabBarController {
    private let disposeBag = DisposeBag()

    private let viewModel: MainViewModel

    private let marketModule = ThemeNavigationController(rootViewController: MarketModule.viewController())
    private let balanceModule = ThemeNavigationController(rootViewController: WalletModule.viewController())
    private let onboardingModule = OnboardingBalanceViewController()
    private let transactionsModule = ThemeNavigationController(rootViewController: TransactionsModule.viewController())
    private let settingsModule = ThemeNavigationController(rootViewController: MainSettingsModule.viewController())

    private var showAlerts = [(() -> ())]()

    private var lastTimeStamp: TimeInterval = 0

    init(viewModel: MainViewModel) {
        self.viewModel = viewModel

        super.init()

        selectedIndex = viewModel.initialTab.rawValue
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        subscribe(disposeBag, viewModel.balanceTabStateDriver) { [weak self] in self?.sync(balanceTabState: $0) }
        subscribe(disposeBag, viewModel.transactionsTabEnabledDriver) { [weak self] in self?.syncTransactionsTab(enabled: $0) }
        subscribe(disposeBag, viewModel.settingsBadgeDriver) { [weak self] in self?.setSettingsBadge(visible: $0.0, count: $0.1) }

        subscribe(disposeBag, viewModel.releaseNotesUrlDriver) { [weak self] url in self?.showReleaseNotes(url: url) }
        subscribe(disposeBag, viewModel.deepLinkDriver) { [weak self] deepLink in self?.handle(deepLink: deepLink) }
        subscribe(disposeBag, viewModel.showSessionRequestSignal) { [weak self] request in self?.handle(request: request) }

        subscribe(disposeBag, viewModel.openWalletConnectSignal) { [weak self] in self?.openWalletConnect(mode: $0) }

        if viewModel.needToShowJailbreakAlert {
            showJailbreakAlert()
        }

        viewModel.onLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showNextAlert()
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let items = tabBar.items, let index = items.firstIndex(of: item), index != selectedIndex, let tab = MainModule.Tab(rawValue: index) {
            viewModel.onSwitch(tab: tab)
        }

        if let items = tabBar.items, items.count > selectedIndex, item == items[selectedIndex] {
            let currentTimestamp = Date().timeIntervalSince1970

            if currentTimestamp - lastTimeStamp < 0.3 {
                handleDoubleClick(index: selectedIndex)
            } else {
                lastTimeStamp = currentTimestamp
            }
        }
    }

    private func handleDoubleClick(index: Int) {
        if let viewControllers = viewControllers, viewControllers.count > index, let navigationController = viewControllers[index] as? UINavigationController, navigationController.topViewController is WalletViewController {
            present(SwitchAccountModule.viewController(), animated: true)
        }
    }

    private func sync(balanceTabState: MainViewModel.BalanceTabState) {
        let balanceTabModule: UIViewController

        switch balanceTabState {
        case .balance: balanceTabModule = balanceModule
        case .onboarding: balanceTabModule = onboardingModule
        }

        viewControllers = [
            marketModule,
            balanceTabModule,
            transactionsModule,
            settingsModule
        ]
    }

    private func syncTransactionsTab(enabled: Bool) {
        transactionsModule.viewControllers.first?.tabBarItem.isEnabled = enabled
    }

    private func setSettingsBadge(visible: Bool, count: Int = 0) {
        settingsModule.viewControllers.first?.tabBarItem.setDotBadge(visible: visible, count: count)
    }

    private func showReleaseNotes(url: URL?) {
        guard let url = url else {
            return
        }

        showAlerts.append({
            let module = MarkdownModule.gitReleaseNotesMarkdownViewController(url: url, presented: true, closeHandler: { [weak self] in
                self?.showNextAlert()
            })
            DispatchQueue.main.async {
                let controller = ThemeNavigationController(rootViewController: module)
                if let delegate = module as? UIAdaptivePresentationControllerDelegate {
                    controller.presentationController?.delegate = delegate
                }
                return self.present(controller, animated: true)
            }
        })
    }

    private func showJailbreakAlert() {
        showAlerts.append({
            let jailbreakAlertController = NoPasscodeViewController(mode: .jailbreak, completion: { [weak self] in
                self?.viewModel.onSuccessJailbreakAlert()
                self?.showNextAlert()
            })
            DispatchQueue.main.async {
                self.present(jailbreakAlertController, animated: true)
            }
        })
    }

    private func showNextAlert() {
        guard let alert = showAlerts.first else {
            return
        }

        alert()
        showAlerts.removeFirst()
    }

    private func handle(deepLink: DeepLinkManager.DeepLink?) {
        guard let deepLink = deepLink else {
            return
        }

        switch deepLink {
        case let .walletConnect(url):
            viewModel.onWalletConnectDeepLink(url: url)
        }
    }

    private func openWalletConnect(mode: MainViewModel.WalletConnectOpenMode) {
        switch mode {
        case .noAccount:
            MainViewController.showWalletConnectError(error: .noAccount, viewController: self)
        case .nonSupportedAccountType(let accountTypeDescription):
            MainViewController.showWalletConnectError(error: .nonSupportedAccountType(accountTypeDescription: accountTypeDescription), viewController: self)
        case .pair(let url):
            WalletConnectUriHandler.connect(uri: url) { [weak self] result in
                self?.processWalletConnectPair(result: result)
            }
        }
    }

    private func processWalletConnectPair(result: Result<IWalletConnectMainService, Error>) {
        DispatchQueue.main.async { [weak self] in
            switch result {
            case .success(let service):
                guard let viewController = WalletConnectMainModule.viewController(
                        service: service,
                        sourceViewController: self?.visibleController)
                else {
                    return
                }

                self?.visibleController.present(viewController, animated: true)
            default: return
            }
        }
    }

    private func handle(request: WalletConnectRequest) {
        guard let viewController = WalletConnectRequestModule.viewController(signService: App.shared.walletConnectV2SessionManager.service, request: request) else {
            return
        }

        visibleController.present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

}

extension MainViewController {

    static func showWalletConnectError(error: WalletConnectOpenError, viewController: UIViewController) {
        switch error {
        case .noAccount:
            let presentingViewController = InformationModule.simpleInfo(
                    title: "wallet_connect.title".localized,
                    image: UIImage(named: "wallet_connect_24")?.withTintColor(.themeJacob),
                    description: "wallet_connect.no_account.description".localized,
                    buttonTitle: "wallet_connect.no_account.i_understand".localized,
                    onTapButton: InformationModule.afterClose())

            viewController.present(presentingViewController, animated: true)
        case .nonSupportedAccountType(let accountTypeDescription):
            let presentingViewController = InformationModule.simpleInfo(
                    title: "wallet_connect.title".localized,
                    image: UIImage(named: "wallet_connect_24")?.withTintColor(.themeJacob),
                    description: "wallet_connect.non_supported_account.description".localized(accountTypeDescription),
                    buttonTitle: "wallet_connect.non_supported_account.switch".localized,
                    onTapButton: InformationModule.afterClose { [weak viewController] in
                        viewController?.present(SwitchAccountModule.viewController(), animated: true)
                    })

            viewController.present(presentingViewController, animated: true)
        }
    }

    enum WalletConnectOpenError {
        case noAccount
        case nonSupportedAccountType(accountTypeDescription: String)
    }

}
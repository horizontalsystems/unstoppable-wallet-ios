import HsToolKit
import RxCocoa
import RxSwift
import StorageKit
import ThemeKit
import UIKit

class MainViewController: ThemeTabBarController {
    private let disposeBag = DisposeBag()

    private let viewModel: MainViewModel

    private var marketModule: UIViewController?
    private let balanceModule = ThemeNavigationController(rootViewController: WalletModule.viewController())
    private let transactionsModule = ThemeNavigationController(rootViewController: TransactionsModule.viewController())
    private let settingsModule = ThemeNavigationController(rootViewController: MainSettingsModule.viewController())

    private var showAlerts = [() -> Void]()

    private var lastTimeStamp: TimeInterval = 0
    private var didAppear: Bool = false

    init(viewModel: MainViewModel) {
        self.viewModel = viewModel

        super.init()

        selectedIndex = viewModel.initialTab.rawValue
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        subscribe(disposeBag, viewModel.balanceTabStateDriver) { [weak self] in self?.sync(balanceTabState: $0) }
        subscribe(disposeBag, viewModel.transactionsTabEnabledDriver) { [weak self] in self?.syncTransactionsTab(enabled: $0) }
        subscribe(disposeBag, viewModel.settingsBadgeDriver) { [weak self] in self?.setSettingsBadge(visible: $0.0, count: $0.1) }

        subscribe(disposeBag, viewModel.showMarketDriver) { [weak self] in self?.handle(showMarket: $0) }
        subscribe(disposeBag, viewModel.showReleaseNotesDriver) { [weak self] in self?.showReleaseNotes(url: $0) }
        subscribe(disposeBag, viewModel.showJailbreakDriver) { [weak self] in self?.showJailbreakAlert() }

        viewModel.onLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        didAppear = true
        viewModel.handleNextAlert()
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

    private func sync(balanceTabState _: MainViewModel.BalanceTabState) {
        var viewControllers = [UIViewController]()
        if viewModel.showMarket {
            let marketModule = marketModule ?? ThemeNavigationController(rootViewController: MarketModule.viewController())
            self.marketModule = marketModule

            viewControllers.append(marketModule)
        } else {
            marketModule = nil
        }

        viewControllers.append(contentsOf: [
            balanceModule,
            transactionsModule,
            settingsModule,
        ])

        setViewControllers(viewControllers, animated: didAppear)
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

        let module = MarkdownModule.gitReleaseNotesMarkdownViewController(url: url, presented: true, closeHandler: { [weak self] in
            self?.viewModel.handleNextAlert()
        })

        let controller = ThemeNavigationController(rootViewController: module)
        if let delegate = module as? UIAdaptivePresentationControllerDelegate {
            controller.presentationController?.delegate = delegate
        }

        present(controller, animated: true)
    }

    private func showJailbreakAlert() {
        viewModel.onSuccessJailbreakAlert()
        let jailbreakAlertController = NoPasscodeViewController(mode: .jailbreak, completion: { [weak self] in
            self?.viewModel.handleNextAlert()
        })
        present(jailbreakAlertController, animated: true)
    }

    private func showNextAlert() {
        guard let alert = showAlerts.first else {
            return
        }

        alert()
        showAlerts.removeFirst()
    }

    private func handle(showMarket _: Bool) {
        sync(balanceTabState: viewModel.balanceTabState)
    }
}

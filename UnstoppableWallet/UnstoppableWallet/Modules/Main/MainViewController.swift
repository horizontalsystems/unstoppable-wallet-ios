import UIKit
import ThemeKit
import RxSwift
import RxCocoa

class MainViewController: ThemeTabBarController {
    private let disposeBag = DisposeBag()

    private let viewModel: MainViewModel

    private let marketModule = ThemeNavigationController(rootViewController: MarketModule.viewController())
    private let balanceModule = ThemeNavigationController(rootViewController: BalanceRouter.module())
    private let onboardingModule = ThemeNavigationController(rootViewController: OnboardingBalanceViewController())
    private let transactionsModule = ThemeNavigationController(rootViewController: TransactionsRouter.module())
    private let settingsModule = ThemeNavigationController(rootViewController: MainSettingsModule.viewController())

    init(viewModel: MainViewModel, selectedIndex: Int) {
        self.viewModel = viewModel

        super.init()

        self.selectedIndex = selectedIndex
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        subscribe(disposeBag, viewModel.balanceTabStateDriver) { [weak self] in self?.sync(balanceTabState: $0) }
        subscribe(disposeBag, viewModel.transactionsTabEnabledDriver) { [weak self] in self?.syncTransactionsTab(enabled: $0) }
        subscribe(disposeBag, viewModel.settingsBadgeDriver) { [weak self] in self?.setSettingsBadge(visible: $0) }

        viewModel.onLoad()
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

    private func setSettingsBadge(visible: Bool) {
        settingsModule.viewControllers.first?.tabBarItem.setDotBadge(visible: visible)
    }

}

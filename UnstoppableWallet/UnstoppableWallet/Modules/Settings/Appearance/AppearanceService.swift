import RxSwift
import RxRelay
import ThemeKit

class AppearanceService {
    private let themeModes: [ThemeMode] = [.system, .dark, .light]

    private let themeManager: ThemeManager
    private let launchScreenManager: LaunchScreenManager
    private let balancePrimaryValueManager: BalancePrimaryValueManager
    private let disposeBag = DisposeBag()

    private let themeModeItemsRelay = PublishRelay<[ThemeModeItem]>()
    private(set) var themeModeItems: [ThemeModeItem] = [] {
        didSet {
            themeModeItemsRelay.accept(themeModeItems)
        }
    }

    private let launchScreenItemsRelay = PublishRelay<[LaunchScreenItem]>()
    private(set) var launchScreenItems: [LaunchScreenItem] = [] {
        didSet {
            launchScreenItemsRelay.accept(launchScreenItems)
        }
    }

    private let balancePrimaryValueItemsRelay = PublishRelay<[BalancePrimaryValueItem]>()
    private(set) var balancePrimaryValueItems: [BalancePrimaryValueItem] = [] {
        didSet {
            balancePrimaryValueItemsRelay.accept(balancePrimaryValueItems)
        }
    }

    init(themeManager: ThemeManager, launchScreenManager: LaunchScreenManager, balancePrimaryValueManager: BalancePrimaryValueManager) {
        self.themeManager = themeManager
        self.launchScreenManager = launchScreenManager
        self.balancePrimaryValueManager = balancePrimaryValueManager

        subscribe(disposeBag, launchScreenManager.launchScreenObservable) { [weak self] in self?.syncLaunchScreenItems(current: $0) }
        subscribe(disposeBag, balancePrimaryValueManager.balancePrimaryValueObservable) { [weak self] in self?.syncBalancePrimaryValueItems(current: $0) }

        syncThemeModeItems()
        syncLaunchScreenItems(current: launchScreenManager.launchScreen)
        syncBalancePrimaryValueItems(current: balancePrimaryValueManager.balancePrimaryValue)
    }

    private func syncThemeModeItems() {
        themeModeItems = themeModes.map { themeMode in
            ThemeModeItem(themeMode: themeMode, current: themeMode == themeManager.themeMode)
        }
    }

    private func syncLaunchScreenItems(current: LaunchScreen) {
        launchScreenItems = LaunchScreen.allCases.map { launchScreen in
            LaunchScreenItem(launchScreen: launchScreen, current: launchScreen == current)
        }
    }

    private func syncBalancePrimaryValueItems(current: BalancePrimaryValue) {
        balancePrimaryValueItems = BalancePrimaryValue.allCases.map { value in
            BalancePrimaryValueItem(value: value, current: value == current)
        }
    }

}

extension AppearanceService {

    var themeModeItemsObservable: Observable<[ThemeModeItem]> {
        themeModeItemsRelay.asObservable()
    }

    var launchScreenItemsObservable: Observable<[LaunchScreenItem]> {
        launchScreenItemsRelay.asObservable()
    }

    var balancePrimaryValueItemsObservable: Observable<[BalancePrimaryValueItem]> {
        balancePrimaryValueItemsRelay.asObservable()
    }

    func setThemeMode(index: Int) {
        themeManager.themeMode = themeModes[index]
        syncThemeModeItems()
    }

    func setLaunchScreen(index: Int) {
        launchScreenManager.launchScreen = LaunchScreen.allCases[index]
    }

    func setBalancePrimaryValue(index: Int) {
        balancePrimaryValueManager.balancePrimaryValue = BalancePrimaryValue.allCases[index]
    }

}

extension AppearanceService {

    struct ThemeModeItem {
        let themeMode: ThemeMode
        let current: Bool
    }

    struct LaunchScreenItem {
        let launchScreen: LaunchScreen
        let current: Bool
    }

    struct BalancePrimaryValueItem {
        let value: BalancePrimaryValue
        let current: Bool
    }

}

import RxSwift
import RxRelay
import ThemeKit
import MarketKit

class AppearanceService {
    private let themeModes: [ThemeMode] = [.system, .dark, .light]

    private let themeManager: ThemeManager
    private let launchScreenManager: LaunchScreenManager
    private let appIconManager: AppIconManager
    private let balancePrimaryValueManager: BalancePrimaryValueManager
    private let balanceConversionManager: BalanceConversionManager
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

    private let appIconItemsRelay = PublishRelay<[AppIconItem]>()
    private(set) var appIconItems: [AppIconItem] = [] {
        didSet {
            appIconItemsRelay.accept(appIconItems)
        }
    }

    private let conversionItemsRelay = PublishRelay<[ConversionItem]>()
    private(set) var conversionItems: [ConversionItem] = [] {
        didSet {
            conversionItemsRelay.accept(conversionItems)
        }
    }

    private let balancePrimaryValueItemsRelay = PublishRelay<[BalancePrimaryValueItem]>()
    private(set) var balancePrimaryValueItems: [BalancePrimaryValueItem] = [] {
        didSet {
            balancePrimaryValueItemsRelay.accept(balancePrimaryValueItems)
        }
    }

    init(themeManager: ThemeManager, launchScreenManager: LaunchScreenManager, appIconManager: AppIconManager, balancePrimaryValueManager: BalancePrimaryValueManager, balanceConversionManager: BalanceConversionManager) {
        self.themeManager = themeManager
        self.launchScreenManager = launchScreenManager
        self.appIconManager = appIconManager
        self.balancePrimaryValueManager = balancePrimaryValueManager
        self.balanceConversionManager = balanceConversionManager

        subscribe(disposeBag, launchScreenManager.launchScreenObservable) { [weak self] in self?.syncLaunchScreenItems(current: $0) }
        subscribe(disposeBag, appIconManager.appIconObservable) { [weak self] in self?.syncAppIconItems(current: $0) }
        subscribe(disposeBag, balancePrimaryValueManager.balancePrimaryValueObservable) { [weak self] in self?.syncBalancePrimaryValueItems(current: $0) }
        subscribe(disposeBag, balanceConversionManager.conversionTokenObservable) { [weak self] in self?.syncConversionItems(current: $0) }

        syncThemeModeItems()
        syncLaunchScreenItems(current: launchScreenManager.launchScreen)
        syncAppIconItems(current: appIconManager.appIcon)
        syncConversionItems(current: balanceConversionManager.conversionToken)
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

    private func syncAppIconItems(current: AppIcon) {
        appIconItems = AppIconManager.allAppIcons.map { appIcon in
            AppIconItem(appIcon: appIcon, current: appIcon == current)
        }
    }

    private func syncConversionItems(current: Token?) {
        conversionItems = balanceConversionManager.conversionTokens.map { token in
            ConversionItem(token: token, current: token == current)
        }
    }

    private func syncBalancePrimaryValueItems(current: BalancePrimaryValue?) {
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

    var appIconItemsObservable: Observable<[AppIconItem]> {
        appIconItemsRelay.asObservable()
    }

    var conversionItemsObservable: Observable<[ConversionItem]> {
        conversionItemsRelay.asObservable()
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

    func setAppIcon(index: Int) {
        appIconManager.appIcon = AppIconManager.allAppIcons[index]
    }

    func setConversionCoin(index: Int) {
        balanceConversionManager.setConversionToken(index: index)
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

    struct AppIconItem {
        let appIcon: AppIcon
        let current: Bool
    }

    struct ConversionItem {
        let token: Token
        let current: Bool
    }

    struct BalancePrimaryValueItem {
        let value: BalancePrimaryValue
        let current: Bool
    }

}

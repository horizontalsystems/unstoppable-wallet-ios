import RxSwift
import RxRelay
import ThemeKit

class AppearanceService {
    private let themeModes: [ThemeMode] = [.system, .dark, .light]

    private let themeManager: ThemeManager
    private let launchScreenManager: LaunchScreenManager
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

    init(themeManager: ThemeManager, launchScreenManager: LaunchScreenManager) {
        self.themeManager = themeManager
        self.launchScreenManager = launchScreenManager

        subscribe(disposeBag, launchScreenManager.launchScreenObservable) { [weak self] in self?.syncLaunchScreenItems(current: $0) }

        syncThemeModeItems()
        syncLaunchScreenItems(current: launchScreenManager.launchScreen)
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

}

extension AppearanceService {

    var themeModeItemsObservable: Observable<[ThemeModeItem]> {
        themeModeItemsRelay.asObservable()
    }

    var launchScreenItemsObservable: Observable<[LaunchScreenItem]> {
        launchScreenItemsRelay.asObservable()
    }

    func setThemeMode(index: Int) {
        themeManager.themeMode = themeModes[index]
        syncThemeModeItems()
    }

    func setLaunchScreen(index: Int) {
        launchScreenManager.launchScreen = LaunchScreen.allCases[index]
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

}

import Combine
import MarketKit
import SwiftUI
import ThemeKit

class AppearanceViewModel: ObservableObject {
    private let themeManager = App.shared.themeManager
    private let launchScreenManager = App.shared.launchScreenManager
    private let appIconManager = App.shared.appIconManager
    private let balancePrimaryValueManager = App.shared.balancePrimaryValueManager
    private let walletButtonHiddenManager = App.shared.walletButtonHiddenManager
    private let priceChangeModeManager = App.shared.priceChangeModeManager

    let themeModes: [ThemeMode] = [.system, .dark, .light]

    @Published var themeMode: ThemeMode {
        didSet {
            guard themeManager.themeMode != themeMode else {
                return
            }
            stat(page: .appearance, event: .selectTheme(type: themeMode.rawValue))
            themeManager.themeMode = themeMode
        }
    }

    @Published var hideMarkets: Bool {
        didSet {
            guard launchScreenManager.showMarket == hideMarkets else {
                return
            }
            stat(page: .appearance, event: .showMarketsTab(shown: !hideMarkets))
            launchScreenManager.showMarket = !hideMarkets
        }
    }

    @Published var priceChangeMode: PriceChangeMode {
        didSet {
            guard priceChangeModeManager.priceChangeMode != priceChangeMode else {
                return
            }
            stat(page: .appearance, event: .showMarketsTab(shown: !hideMarkets))
            priceChangeModeManager.priceChangeMode = priceChangeMode
        }
    }

    @Published var launchScreen: LaunchScreen {
        didSet {
            guard launchScreenManager.launchScreen != launchScreen else {
                return
            }
            stat(page: .appearance, event: .selectLaunchScreen(type: launchScreen.statType))
            launchScreenManager.launchScreen = launchScreen
        }
    }

    @Published var hideBalanceButtons: Bool {
        didSet {
            guard walletButtonHiddenManager.buttonHidden != hideBalanceButtons else {
                return
            }
            stat(page: .appearance, event: .hideBalanceButtons(hide: hideBalanceButtons))
            walletButtonHiddenManager.buttonHidden = hideBalanceButtons
        }
    }

    @Published var balancePrimaryValue: BalancePrimaryValue {
        didSet {
            guard balancePrimaryValueManager.balancePrimaryValue != balancePrimaryValue else {
                return
            }
            stat(page: .appearance, event: .selectBalanceValue(type: balancePrimaryValue.rawValue))
            balancePrimaryValueManager.balancePrimaryValue = balancePrimaryValue
        }
    }

    @Published var appIcon: AppIcon {
        didSet {
            guard appIconManager.appIcon != appIcon else {
                return
            }
            stat(page: .appearance, event: .selectAppIcon(iconUid: appIcon.title.lowercased()))
            appIconManager.appIcon = appIcon
        }
    }

    init() {
        themeMode = themeManager.themeMode
        hideMarkets = !launchScreenManager.showMarket
        priceChangeMode = priceChangeModeManager.priceChangeMode
        launchScreen = launchScreenManager.launchScreen
        hideBalanceButtons = walletButtonHiddenManager.buttonHidden
        balancePrimaryValue = balancePrimaryValueManager.balancePrimaryValue
        appIcon = appIconManager.appIcon
    }
}

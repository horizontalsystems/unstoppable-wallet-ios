import MarketKit
import SwiftUI
import ThemeKit

class AppearanceViewModel: ObservableObject {
    private let themeManager = App.shared.themeManager
    private let launchScreenManager = App.shared.launchScreenManager
    private let appIconManager = App.shared.appIconManager
    private let balancePrimaryValueManager = App.shared.balancePrimaryValueManager
    private let balanceConversionManager = App.shared.balanceConversionManager

    let themeModes: [ThemeMode] = [.system, .dark, .light]
    let conversionTokens: [Token]

    @Published var themeMode: ThemeMode {
        didSet {
            guard themeManager.themeMode != themeMode else {
                return 
            }
            stat(page: .appearance, event: .selectTheme(type: themeMode.rawValue))
            themeManager.themeMode = themeMode
        }
    }

    @Published var showMarketTab: Bool {
        didSet {
            guard launchScreenManager.showMarket != showMarketTab else {
                return 
            }
            stat(page: .appearance, event: .showMarketsTab(shown: showMarketTab))
            launchScreenManager.showMarket = showMarketTab
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

    @Published var conversionToken: Token? {
        didSet {
            guard balanceConversionManager.conversionToken != conversionToken else {
                return 
            }
            if let conversionToken {
                stat(page: .appearance, event: .selectBalanceConversion(coinUid: conversionToken.coin.uid))
            }
            balanceConversionManager.set(conversionToken: conversionToken)
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
        conversionTokens = balanceConversionManager.conversionTokens

        themeMode = themeManager.themeMode
        showMarketTab = launchScreenManager.showMarket
        launchScreen = launchScreenManager.launchScreen
        conversionToken = balanceConversionManager.conversionToken
        balancePrimaryValue = balancePrimaryValueManager.balancePrimaryValue
        appIcon = appIconManager.appIcon
    }
}

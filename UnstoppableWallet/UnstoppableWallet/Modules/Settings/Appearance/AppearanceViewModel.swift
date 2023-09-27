import MarketKit
import SwiftUI
import ThemeKit

class AppearanceViewModel: ObservableObject {
    private let themeManager: ThemeManager
    private let launchScreenManager: LaunchScreenManager
    private let appIconManager: AppIconManager
    private let balancePrimaryValueManager: BalancePrimaryValueManager
    private let balanceConversionManager: BalanceConversionManager

    let themeModes: [ThemeMode] = [.system, .dark, .light]
    let conversionTokens: [Token]

    @Published var themMode: ThemeMode {
        didSet {
            themeManager.themeMode = themMode
        }
    }

    @Published var showMarketTab: Bool {
        didSet {
            launchScreenManager.showMarket = showMarketTab
        }
    }

    @Published var launchScreen: LaunchScreen {
        didSet {
            launchScreenManager.launchScreen = launchScreen
        }
    }

    @Published var conversionToken: Token? {
        didSet {
            balanceConversionManager.set(conversionToken: conversionToken)
        }
    }

    @Published var balancePrimaryValue: BalancePrimaryValue {
        didSet {
            balancePrimaryValueManager.balancePrimaryValue = balancePrimaryValue
        }
    }

    @Published var appIcon: AppIcon {
        didSet {
            appIconManager.appIcon = appIcon
        }
    }

    init(themeManager: ThemeManager, launchScreenManager: LaunchScreenManager, appIconManager: AppIconManager, balancePrimaryValueManager: BalancePrimaryValueManager, balanceConversionManager: BalanceConversionManager) {
        self.themeManager = themeManager
        self.launchScreenManager = launchScreenManager
        self.appIconManager = appIconManager
        self.balancePrimaryValueManager = balancePrimaryValueManager
        self.balanceConversionManager = balanceConversionManager

        conversionTokens = balanceConversionManager.conversionTokens

        themMode = themeManager.themeMode
        showMarketTab = launchScreenManager.showMarket
        launchScreen = launchScreenManager.launchScreen
        conversionToken = balanceConversionManager.conversionToken
        balancePrimaryValue = balancePrimaryValueManager.balancePrimaryValue
        appIcon = appIconManager.appIcon
    }
}

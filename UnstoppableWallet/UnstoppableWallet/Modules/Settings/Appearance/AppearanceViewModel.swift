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

    init() {
        conversionTokens = balanceConversionManager.conversionTokens

        themMode = themeManager.themeMode
        showMarketTab = launchScreenManager.showMarket
        launchScreen = launchScreenManager.launchScreen
        conversionToken = balanceConversionManager.conversionToken
        balancePrimaryValue = balancePrimaryValueManager.balancePrimaryValue
        appIcon = appIconManager.appIcon
    }
}

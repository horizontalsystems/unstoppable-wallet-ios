import Combine
import MarketKit
import SwiftUI
import ThemeKit

class AppearanceViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    private let themeManager = App.shared.themeManager
    private let launchScreenManager = App.shared.launchScreenManager
    private let appIconManager = App.shared.appIconManager
    private let balancePrimaryValueManager = App.shared.balancePrimaryValueManager
    private let balanceConversionManager = App.shared.balanceConversionManager
    private let walletButtonHiddenManager = App.shared.walletButtonHiddenManager
    private let currencyManager = App.shared.currencyManager
    private let languageManager = LanguageManager.shared

    let themeModes: [ThemeMode] = [.system, .dark, .light]
    let conversionTokens: [Token]

    var currentLanguageDisplayName: String? {
        languageManager.currentLanguageDisplayName
    }

    @Published var baseCurrency: Currency

    @Published var themMode: ThemeMode {
        didSet {
            themeManager.themeMode = themMode
        }
    }

    @Published var hideMarketTab: Bool {
        didSet {
            launchScreenManager.showMarket = !hideMarketTab
        }
    }

    @Published var hideBalanceButtons: Bool {
        didSet {
            walletButtonHiddenManager.buttonHidden = hideBalanceButtons
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
        hideMarketTab = !launchScreenManager.showMarket
        launchScreen = launchScreenManager.launchScreen
        conversionToken = balanceConversionManager.conversionToken
        balancePrimaryValue = balancePrimaryValueManager.balancePrimaryValue
        appIcon = appIconManager.appIcon
        baseCurrency = currencyManager.baseCurrency
        hideBalanceButtons = walletButtonHiddenManager.buttonHidden

        currencyManager.$baseCurrency.sink { [weak self] in self?.baseCurrency = $0 }.store(in: &cancellables)
    }
}

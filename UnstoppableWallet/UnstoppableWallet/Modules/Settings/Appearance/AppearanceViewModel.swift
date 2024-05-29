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
    private let priceChangeModeManager = App.shared.priceChangeModeManager

    let themeModes: [ThemeMode] = [.system, .dark, .light]
    let conversionTokens: [Token]

    @Published var themeMode: ThemeMode {
        didSet {
            themeManager.themeMode = themeMode
        }
    }

    @Published var hideMarkets: Bool {
        didSet {
            launchScreenManager.showMarket = !hideMarkets
        }
    }

    @Published var priceChangeMode: PriceChangeMode {
        didSet {
            priceChangeModeManager.priceChangeMode = priceChangeMode
        }
    }

    @Published var launchScreen: LaunchScreen {
        didSet {
            launchScreenManager.launchScreen = launchScreen
        }
    }

    @Published var hideBalanceButtons: Bool {
        didSet {
            walletButtonHiddenManager.buttonHidden = hideBalanceButtons
        }
    }

    @Published var balancePrimaryValue: BalancePrimaryValue {
        didSet {
            balancePrimaryValueManager.balancePrimaryValue = balancePrimaryValue
        }
    }

    @Published var conversionToken: Token? {
        didSet {
            balanceConversionManager.set(conversionToken: conversionToken)
        }
    }

    @Published var appIcon: AppIcon {
        didSet {
            appIconManager.appIcon = appIcon
        }
    }

    init() {
        conversionTokens = balanceConversionManager.conversionTokens

        themeMode = themeManager.themeMode
        hideMarkets = !launchScreenManager.showMarket
        priceChangeMode = priceChangeModeManager.priceChangeMode
        launchScreen = launchScreenManager.launchScreen
        hideBalanceButtons = walletButtonHiddenManager.buttonHidden
        balancePrimaryValue = balancePrimaryValueManager.balancePrimaryValue
        conversionToken = balanceConversionManager.conversionToken
        appIcon = appIconManager.appIcon

        balanceConversionManager.$conversionToken.sink { [weak self] in self?.conversionToken = $0 }.store(in: &cancellables)
    }
}

import Combine
import MarketKit
import SwiftUI

class AppearanceViewModel: ObservableObject {
    private static let defaultHideMarkets = !LaunchScreenManager.defaultShowMarket

    private let themeManager = Core.shared.themeManager
    private let launchScreenManager = Core.shared.launchScreenManager
    private let appIconManager = Core.shared.appIconManager
    private let appSettingManager = Core.shared.appSettingManager
    private let walletButtonHiddenManager = Core.shared.walletButtonHiddenManager
    private let priceChangeModeManager = Core.shared.priceChangeModeManager
    private let currencyManager = Core.shared.currencyManager
    private let amountRoundingManager = Core.shared.amountRoundingManager
    private let recentlySentManager = Core.shared.recentlySentManager

    private var cancellables = Set<AnyCancellable>()

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

    @Published var baseCurrencyCode: String = ""

    @Published var hideMarkets: Bool {
        didSet {
            guard launchScreenManager.showMarket == hideMarkets else {
                return
            }
            stat(page: .appearance, event: .showMarketsTab(shown: !hideMarkets))
            launchScreenManager.showMarket = !hideMarkets
            launchScreen = launchScreenManager.launchScreen
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

    @Published var useAmountRounding: Bool {
        didSet {
            guard amountRoundingManager.useAmountRounding != useAmountRounding else {
                return
            }
            stat(page: .appearance, event: .amountRounding(use: useAmountRounding))
            amountRoundingManager.useAmountRounding = useAmountRounding
        }
    }

    @Published var showRecentlySent: Bool {
        didSet {
            guard recentlySentManager.recentlySent != showRecentlySent else {
                return
            }
            stat(page: .appearance, event: .recentlySent(show: showRecentlySent))
            recentlySentManager.recentlySent = showRecentlySent
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
            guard appSettingManager.balancePrimaryValue != balancePrimaryValue else {
                return
            }
            stat(page: .appearance, event: .selectBalanceValue(type: balancePrimaryValue.rawValue))
            appSettingManager.balancePrimaryValue = balancePrimaryValue
        }
    }

    @Published var appIcon: AppIcon {
        didSet {
            guard appIconManager.appIcon != appIcon || appIconManager.isSystemIconOutOfSync else {
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
        useAmountRounding = amountRoundingManager.useAmountRounding
        showRecentlySent = recentlySentManager.recentlySent
        hideBalanceButtons = walletButtonHiddenManager.buttonHidden
        balancePrimaryValue = appSettingManager.balancePrimaryValue
        appIcon = appIconManager.appIcon

        subscribe(&cancellables, currencyManager.$baseCurrency) { [weak self] _ in self?.syncBaseCurrencyCode() }

        syncBaseCurrencyCode()
    }

    private func syncBaseCurrencyCode() {
        baseCurrencyCode = currencyManager.baseCurrency.code
    }
}

extension AppearanceViewModel {
    var canReset: Bool {
        themeMode != ThemeManager.defaultThemeMode
            || baseCurrencyCode != currencyManager.defaultCurrency.code
            || hideMarkets != Self.defaultHideMarkets
            || priceChangeMode != PriceChangeModeManager.defaultPriceChangeMode
            || launchScreen != LaunchScreenManager.defaultLaunchScreen
            || useAmountRounding != AmountRoundingManager.defaultUseAmountRounding
            || showRecentlySent != RecentlySentManager.defaultRecentlySent
            || hideBalanceButtons != WalletButtonHiddenManager.defaultButtonHidden
            || balancePrimaryValue != AppSettingManager.defaultBalancePrimaryValue
            || appIcon != AppIconManager.defaultAppIcon
    }

    func reset() {
        // `hideMarkets` must be reset before `launchScreen`: while markets are hidden the manager reports `.auto` for the launch screen
        hideMarkets = Self.defaultHideMarkets
        launchScreen = LaunchScreenManager.defaultLaunchScreen
        themeMode = ThemeManager.defaultThemeMode
        priceChangeMode = PriceChangeModeManager.defaultPriceChangeMode
        hideBalanceButtons = WalletButtonHiddenManager.defaultButtonHidden
        useAmountRounding = AmountRoundingManager.defaultUseAmountRounding
        balancePrimaryValue = AppSettingManager.defaultBalancePrimaryValue
        showRecentlySent = RecentlySentManager.defaultRecentlySent

        let defaultCurrency = currencyManager.defaultCurrency
        if currencyManager.baseCurrency.code != defaultCurrency.code {
            stat(page: .appearance, event: .switchBaseCurrency(code: defaultCurrency.code))
            currencyManager.baseCurrency = defaultCurrency
            syncBaseCurrencyCode()
        }

        // last, as changing the app icon may show a system alert
        appIcon = AppIconManager.defaultAppIcon
    }
}

import Foundation
import Chart
import CurrencyKit
import ThemeKit

struct AppearanceBackup {
    let lockTimeEnabled: Bool
    let remoteContactsSync: Bool
    let defaultProviders: [DefaultProvider]
    let chartIndicators: [ChartIndicator]
    let indicatorsShown: Bool
    let currentLanguage: String
    let baseCurrency: Currency

    let mode: ThemeMode
    let showMarketTab: Bool
    let launchScreen: LaunchScreen
    let conversionTokenQueryId: String?
    let balancePrimaryValue: BalancePrimaryValue
    let balanceAutoHide: Bool
    let appIcon: AppIcon
}

extension AppearanceBackup {
    struct DefaultProvider {
        let blockchainTypeId: String
        let provider: String
    }
}
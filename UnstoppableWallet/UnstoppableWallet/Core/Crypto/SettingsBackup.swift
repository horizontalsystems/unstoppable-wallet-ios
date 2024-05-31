import Chart
import Foundation
import ThemeKit

class SettingsBackup: Codable {
    var evmSyncSources: EvmSyncSourceManager.SyncSourceBackup
    let btcModes: [BtcBlockchainManager.BtcRestoreModeBackup]

    let remoteContactsSync: Bool?
    let swapProviders: [DefaultProvider]
    let chartIndicators: ChartIndicatorsRepository.BackupIndicators
    let indicatorsShown: Bool
    let currentLanguage: String
    let baseCurrency: String

    let mode: ThemeMode
    let showMarketTab: Bool
    let priceChangeMode: PriceChangeMode
    let launchScreen: LaunchScreen
    let conversionTokenQueryId: String?
    let balanceHideButtons: Bool
    let balancePrimaryValue: BalancePrimaryValue
    let balanceAutoHide: Bool
    let appIcon: String

    enum CodingKeys: String, CodingKey {
        case evmSyncSources = "evm_sync_sources"
        case btcModes = "btc_modes"
        case remoteContactsSync = "contacts_sync"
        case swapProviders = "swap_providers"
        case chartIndicators = "indicators"
        case indicatorsShown = "indicators_shown"
        case currentLanguage = "language"
        case baseCurrency = "currency"
        case mode = "theme_mode"
        case showMarketTab = "show_market"
        case priceChangeMode = "price_change_mode"
        case launchScreen = "launch_screen"
        case conversionTokenQueryId = "conversion_token_query_id"
        case balanceHideButtons = "balance_hide_buttons"
        case balancePrimaryValue = "balance_primary_value"
        case balanceAutoHide = "balance_auto_hide"
        case appIcon = "app_icon"
    }
    
    init(
        evmSyncSources: EvmSyncSourceManager.SyncSourceBackup,
        btcModes: [BtcBlockchainManager.BtcRestoreModeBackup],
        remoteContactsSync: Bool?,
        swapProviders: [DefaultProvider],
        chartIndicators: ChartIndicatorsRepository.BackupIndicators,
        indicatorsShown: Bool,
        currentLanguage: String,
        baseCurrency: String,
        mode: ThemeMode,
        showMarketTab: Bool,
        priceChangeMode: PriceChangeMode,
        launchScreen: LaunchScreen,
        conversionTokenQueryId: String?,
        balanceHideButtons: Bool,
        balancePrimaryValue: BalancePrimaryValue,
        balanceAutoHide: Bool,
        appIcon: String) {
            self.evmSyncSources = evmSyncSources
            self.btcModes = btcModes
            self.remoteContactsSync = remoteContactsSync
            self.swapProviders = swapProviders
            self.chartIndicators = chartIndicators
            self.indicatorsShown = indicatorsShown
            self.currentLanguage = currentLanguage
            self.baseCurrency = baseCurrency
            self.mode = mode
            self.showMarketTab = showMarketTab
            self.priceChangeMode = priceChangeMode
            self.launchScreen = launchScreen
            self.conversionTokenQueryId = conversionTokenQueryId
            self.balanceHideButtons = balanceHideButtons
            self.balancePrimaryValue = balancePrimaryValue
            self.balanceAutoHide = balanceAutoHide
            self.appIcon = appIcon
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        evmSyncSources = try container.decode(EvmSyncSourceManager.SyncSourceBackup.self, forKey: .evmSyncSources)
        btcModes = try container.decode([BtcBlockchainManager.BtcRestoreModeBackup].self, forKey: .btcModes)
        remoteContactsSync = try? container.decode(Bool.self, forKey: .remoteContactsSync)
        swapProviders = try container.decode([DefaultProvider].self, forKey: .swapProviders)
        chartIndicators = try container.decode(ChartIndicatorsRepository.BackupIndicators.self, forKey: .chartIndicators)
        indicatorsShown = try container.decode(Bool.self, forKey: .indicatorsShown)
        currentLanguage = try container.decode(String.self, forKey: .currentLanguage)
        baseCurrency = try container.decode(String.self, forKey: .baseCurrency)
        mode = try container.decode(ThemeMode.self, forKey: .mode)
        showMarketTab = try container.decode(Bool.self, forKey: .showMarketTab)
        priceChangeMode = (try? container.decode(PriceChangeMode.self, forKey: .priceChangeMode)) ?? .hour24
        launchScreen = try container.decode(LaunchScreen.self, forKey: .launchScreen)
        conversionTokenQueryId = try container.decode(String?.self, forKey: .conversionTokenQueryId)
        balanceHideButtons = (try? container.decode(Bool.self, forKey: .balanceHideButtons)) ?? false
        balancePrimaryValue = try container.decode(BalancePrimaryValue.self, forKey: .balancePrimaryValue)
        balanceAutoHide = try container.decode(Bool.self, forKey: .balanceAutoHide)
        appIcon = try container.decode(String.self, forKey: .appIcon)
    }

}

extension SettingsBackup {
    struct DefaultProvider: Codable {
        let blockchainTypeId: String
        let provider: String

        enum CodingKeys: String, CodingKey {
            case blockchainTypeId = "blockchain_type_id"
            case provider
        }
    }
}

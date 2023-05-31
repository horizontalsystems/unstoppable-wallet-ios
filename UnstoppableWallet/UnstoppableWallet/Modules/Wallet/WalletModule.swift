import UIKit
import ThemeKit
import RxSwift
import StorageKit
import LanguageKit
import MarketKit
import CurrencyKit

struct WalletModule {

    static func viewController() -> UIViewController {
        let adapterService = WalletAdapterService(adapterManager: App.shared.adapterManager)

        let coinPriceService = WalletCoinPriceService(
                currencyKit: App.shared.currencyKit,
                marketKit: App.shared.marketKit
        )

        let service = WalletService(
                adapterService: adapterService,
                coinPriceService: coinPriceService,
                cacheManager: App.shared.enabledWalletCacheManager,
                accountManager: App.shared.accountManager,
                accountRestoreWarningManager: App.shared.accountRestoreWarningManager,
                cloudAccountBackupManager: App.shared.cloudAccountBackupManager,
                walletManager: App.shared.walletManager,
                marketKit: App.shared.marketKit,
                localStorage: StorageKit.LocalStorage.default,
                rateAppManager: App.shared.rateAppManager,
                balancePrimaryValueManager: App.shared.balancePrimaryValueManager,
                balanceHiddenManager: App.shared.balanceHiddenManager,
                balanceConversionManager: App.shared.balanceConversionManager,
                appManager: App.shared.appManager,
                feeCoinProvider: App.shared.feeCoinProvider,
                reachabilityManager: App.shared.reachabilityManager
        )

        adapterService.delegate = service
        coinPriceService.delegate = service

        let accountRestoreWarningFactory = AccountRestoreWarningFactory(
                appConfigProvider: App.shared.appConfigProvider,
                localStorage: StorageKit.LocalStorage.default,
                languageManager: LanguageManager.shared)
        let viewModel = WalletViewModel(
                service: service,
                factory: WalletViewItemFactory(),
                accountRestoreWarningFactory: accountRestoreWarningFactory
        )

        return WalletViewController(viewModel: viewModel)
    }

}

protocol IBalanceItem {
    var item: WalletModule.Item { get }
    var isMainNet: Bool { get }
    var balanceData: BalanceData { get }
    var state: AdapterState { get }
    var buttons: [WalletModule.Button: ButtonState] { get }
    var priceItem: WalletCoinPriceService.Item? { get }
}

extension WalletModule {

    enum Item: Hashable {
        case _wallet(wallet: Wallet)
        case _coin(coin: Coin, account: Account)

        var coin: Coin {
            switch self {
            case ._wallet(let wallet): return wallet.coin
            case ._coin(let coin, _): return coin
            }
        }

        var wallet: Wallet? {
            switch self {
            case ._wallet(let wallet): return wallet
            default: return nil
            }
        }

        var decimals: Int {
            switch self {
            case ._wallet(let wallet): return wallet.decimals
            case ._coin: return 8 // todo: how many decimals for coin???
            }
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case ._wallet(let wallet):
                hasher.combine(wallet)
            case ._coin(let coin, let account):
                hasher.combine(coin)
                hasher.combine(account)
            }
        }

        static func ==(lhs: Item, rhs: Item) -> Bool {
            switch (lhs, rhs) {
            case (._wallet(let lhsWallet), ._wallet(let rhsWallet)): return lhsWallet == rhsWallet
            case (._coin(let lhsCoin, let lhsAccount), ._coin(let rhsCoin, let rhsAccount)): return lhsCoin == rhsCoin && lhsAccount == rhsAccount
            default: return false
            }
        }
    }

    enum Button: CaseIterable {
        case send
        case receive
        case address
        case swap
        case chart
    }

    struct ButtonItem {
        let button: Button
        let state: ButtonState
    }

    struct TotalItem {
        let currencyValue: CurrencyValue
        let expired: Bool
        let convertedValue: CoinValue?
        let convertedValueExpired: Bool
    }

    enum SortType: String, CaseIterable {
        case balance
        case name
        case percentGrowth

        var title: String {
            switch self {
            case .balance: return "balance.sort.valueHighToLow".localized
            case .name: return "balance.sort.az".localized
            case .percentGrowth: return "balance.sort.price_change".localized
            }
        }

    }

}

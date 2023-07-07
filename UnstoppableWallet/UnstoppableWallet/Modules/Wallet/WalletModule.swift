import UIKit
import ThemeKit
import RxSwift
import StorageKit
import LanguageKit
import MarketKit
import CurrencyKit

struct WalletModule {

    static func viewController() -> UIViewController {
        let coinPriceService = WalletCoinPriceService(
                currencyKit: App.shared.currencyKit,
                marketKit: App.shared.marketKit
        )

        let elementServiceFactory = WalletElementServiceFactory(
                adapterManager: App.shared.adapterManager,
                walletManager: App.shared.walletManager,
                cexAssetManager: App.shared.cexAssetManager,
                cexProviderFactory: App.shared.cexProviderFactory
        )

        let service = WalletService(
                elementServiceFactory: elementServiceFactory,
                coinPriceService: coinPriceService,
                accountManager: App.shared.accountManager,
                cacheManager: App.shared.enabledWalletCacheManager,
                accountRestoreWarningManager: App.shared.accountRestoreWarningManager,
                reachabilityManager: App.shared.reachabilityManager,
                balancePrimaryValueManager: App.shared.balancePrimaryValueManager,
                balanceHiddenManager: App.shared.balanceHiddenManager,
                balanceConversionManager: App.shared.balanceConversionManager,
                cloudAccountBackupManager: App.shared.cloudAccountBackupManager,
                rateAppManager: App.shared.rateAppManager,
                appManager: App.shared.appManager,
                feeCoinProvider: App.shared.feeCoinProvider,
                localStorage: StorageKit.LocalStorage.default
        )

        coinPriceService.delegate = service

        let accountRestoreWarningFactory = AccountRestoreWarningFactory(
                appConfigProvider: App.shared.appConfigProvider,
                localStorage: StorageKit.LocalStorage.default,
                languageManager: LanguageManager.shared
        )

        let viewModel = WalletViewModel(
                service: service,
                factory: WalletViewItemFactory(),
                accountRestoreWarningFactory: accountRestoreWarningFactory
        )

        return WalletViewController(viewModel: viewModel)
    }

}

extension WalletModule {

    enum ElementState: CustomStringConvertible {
        case loading
        case loaded(elements: [Element])
        case failed(reason: FailureReason)

        var description: String {
            switch self {
            case .loading: return "loading"
            case .loaded(let elements): return "loaded: \(elements.count) elements"
            case .failed: return "failed"
            }
        }
    }

    enum FailureReason: Error {
        case syncFailed
        case invalidApiKey
    }

    enum Element: Hashable {
        case wallet(wallet: Wallet)
        case cexAsset(cexAsset: CexAsset)

        var name: String {
            switch self {
            case .wallet(let wallet): return wallet.coin.code
            case .cexAsset(let cexAsset): return cexAsset.coinCode
            }
        }

        var coin: Coin? {
            switch self {
            case .wallet(let wallet): return wallet.coin
            case .cexAsset(let cexAsset): return cexAsset.coin
            }
        }

        var wallet: Wallet? {
            switch self {
            case .wallet(let wallet): return wallet
            default: return nil
            }
        }

        var cexAsset: CexAsset? {
            switch self {
            case .cexAsset(let cexAsset): return cexAsset
            default: return nil
            }
        }

        var decimals: Int {
            switch self {
            case .wallet(let wallet): return wallet.decimals
            case .cexAsset: return 8 // todo: how many decimals for coin???
            }
        }

        var priceCoinUid: String? {
            switch self {
            case .wallet(let wallet): return wallet.token.isCustom ? nil : wallet.coin.uid
            case .cexAsset(let cexAsset): return cexAsset.coin?.uid
            }
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .wallet(let wallet):
                hasher.combine(wallet)
            case .cexAsset(let cexAsset):
                hasher.combine(cexAsset)
            }
        }

        static func ==(lhs: Element, rhs: Element) -> Bool {
            switch (lhs, rhs) {
            case (.wallet(let lhsWallet), .wallet(let rhsWallet)): return lhsWallet == rhsWallet
            case (.cexAsset(let lhsCexAsset), .cexAsset(let rhsCexAsset)): return lhsCexAsset == rhsCexAsset
            default: return false
            }
        }
    }

    enum Button: CaseIterable {
        case send
        case withdraw
        case receive
        case deposit
        case address
        case swap
        case chart
    }

    struct ButtonItem {
        let button: Button
        let state: ButtonState
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

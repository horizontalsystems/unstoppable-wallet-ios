import CurrencyKit
import LanguageKit
import MarketKit
import RxSwift
import StorageKit
import ThemeKit
import UIKit

struct WalletModule {
    static func viewController() -> UIViewController {
        let coinPriceService = WalletCoinPriceService(
            tag: "wallet",
            currencyKit: App.shared.currencyKit,
            marketKit: App.shared.marketKit
        )

        let elementServiceFactory = WalletElementServiceFactory(
            adapterManager: App.shared.adapterManager,
            walletManager: App.shared.walletManager,
            cexAssetManager: App.shared.cexAssetManager
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
            cloudAccountBackupManager: App.shared.cloudBackupManager,
            rateAppManager: App.shared.rateAppManager,
            appManager: App.shared.appManager,
            feeCoinProvider: App.shared.feeCoinProvider,
            localStorage: StorageKit.LocalStorage.default
        )

        coinPriceService.delegate = service

        let accountRestoreWarningFactory = AccountRestoreWarningFactory(
            localStorage: StorageKit.LocalStorage.default,
            languageManager: LanguageManager.shared
        )

        let viewModel = WalletViewModel(
            service: service,
            eventHandler: App.shared.appEventHandler,
            factory: WalletViewItemFactory(),
            accountRestoreWarningFactory: accountRestoreWarningFactory
        )

        return WalletViewController(viewModel: viewModel)
    }

    static func sendTokenListViewController() -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        let coinPriceService = WalletCoinPriceService(
            tag: "send-token-list",
            currencyKit: App.shared.currencyKit,
            marketKit: App.shared.marketKit
        )

        let adapterService = WalletAdapterService(account: account, adapterManager: App.shared.adapterManager)
        let elementService = WalletBlockchainElementService(
            account: account,
            adapterService: adapterService,
            walletManager: App.shared.walletManager
        )
        adapterService.delegate = elementService

        let service = WalletTokenListService(
            elementService: elementService,
            coinPriceService: coinPriceService,
            cacheManager: App.shared.enabledWalletCacheManager,
            reachabilityManager: App.shared.reachabilityManager,
            balancePrimaryValueManager: App.shared.balancePrimaryValueManager,
            appManager: App.shared.appManager,
            feeCoinProvider: App.shared.feeCoinProvider,
            account: account
        )
        elementService.delegate = service
        coinPriceService.delegate = service

        let viewModel = WalletTokenListViewModel(
            service: service,
            factory: WalletTokenListViewItemFactory(),
            title: "send.send".localized,
            emptyText: "send.no_assets".localized
        )

        let dataSourceChain = DataSourceChain()
        let dataSource = WalletTokenListDataSource(viewModel: viewModel)
        dataSource.delegate = dataSourceChain
        dataSourceChain.append(source: dataSource)

        let viewController = WalletTokenListViewController(viewModel: viewModel, dataSource: dataSourceChain)
        dataSource.viewController = viewController
        dataSource.onSelectWallet = { [weak viewController] wallet in
            if let module = SendModule.controller(wallet: wallet) {
                viewController?.navigationController?.pushViewController(module, animated: true)
            }
        }

        return ThemeNavigationController(rootViewController: viewController)
    }

    static func swapTokenListViewController() -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        let coinPriceService = WalletCoinPriceService(
            tag: "swap-token-list",
            currencyKit: App.shared.currencyKit,
            marketKit: App.shared.marketKit
        )

        let adapterService = WalletAdapterService(account: account, adapterManager: App.shared.adapterManager)
        let elementService = WalletBlockchainElementService(
            account: account,
            adapterService: adapterService,
            walletManager: App.shared.walletManager
        )
        adapterService.delegate = elementService

        let service = WalletTokenListService(
            elementService: elementService,
            coinPriceService: coinPriceService,
            cacheManager: App.shared.enabledWalletCacheManager,
            reachabilityManager: App.shared.reachabilityManager,
            balancePrimaryValueManager: App.shared.balancePrimaryValueManager,
            appManager: App.shared.appManager,
            feeCoinProvider: App.shared.feeCoinProvider,
            account: account
        )
        service.elementFilter = { element in element.wallet?.token.swappable ?? false }

        elementService.delegate = service
        coinPriceService.delegate = service

        let viewModel = WalletTokenListViewModel(
            service: service,
            factory: WalletTokenListViewItemFactory(),
            title: "swap.title".localized,
            emptyText: "swap.no_assets".localized
        )

        let dataSourceChain = DataSourceChain()
        let dataSource = WalletTokenListDataSource(viewModel: viewModel)
        dataSource.delegate = dataSourceChain
        dataSourceChain.append(source: dataSource)

        let viewController = WalletTokenListViewController(viewModel: viewModel, dataSource: dataSourceChain)
        dataSource.viewController = viewController
        dataSource.onSelectWallet = { [weak viewController] wallet in
            if let module = SwapModule.viewController(tokenFrom: wallet.token) {
                viewController?.navigationController?.pushViewController(module, animated: true)
            }
        }

        return ThemeNavigationController(rootViewController: viewController)
    }

    static func donateTokenListViewController() -> UIViewController? {
        let service: IWalletTokenListService
        if let account = App.shared.accountManager.activeAccount, !account.watchAccount, !account.cexAccount {
            let coinPriceService = WalletCoinPriceService(
                tag: "send-token-list",
                currencyKit: App.shared.currencyKit,
                marketKit: App.shared.marketKit
            )

            let adapterService = WalletAdapterService(account: account, adapterManager: App.shared.adapterManager)
            let elementService = WalletBlockchainElementService(
                account: account,
                adapterService: adapterService,
                walletManager: App.shared.walletManager
            )
            adapterService.delegate = elementService

            let tokenListService = WalletTokenListService(
                elementService: elementService,
                coinPriceService: coinPriceService,
                cacheManager: App.shared.enabledWalletCacheManager,
                reachabilityManager: App.shared.reachabilityManager,
                balancePrimaryValueManager: App.shared.balancePrimaryValueManager,
                appManager: App.shared.appManager,
                feeCoinProvider: App.shared.feeCoinProvider,
                account: account
            )
            elementService.delegate = tokenListService
            coinPriceService.delegate = tokenListService

            service = tokenListService
        } else {
            service = NoAccountWalletTokenListService(
                reachabilityManager: App.shared.reachabilityManager,
                balancePrimaryValueManager: App.shared.balancePrimaryValueManager
            )
        }

        let viewModel = WalletTokenListViewModel(
            service: service,
            factory: WalletTokenListViewItemFactory(),
            title: "donate.list.title".localized,
            emptyText: "donate.no_assets".localized
        )

        let dataSourceChain = DataSourceChain()
        let descriptionDataSource = DonateDescriptionDataSource()
        descriptionDataSource.delegate = dataSourceChain
        dataSourceChain.append(source: descriptionDataSource)

        let dataSource = WalletTokenListDataSource(viewModel: viewModel)
        dataSource.delegate = dataSourceChain
        dataSourceChain.append(source: dataSource)

        let viewController = WalletTokenListViewController(viewModel: viewModel, dataSource: dataSourceChain)

        descriptionDataSource.viewController = viewController
        dataSource.viewController = viewController
        dataSource.onSelectWallet = { [weak viewController] wallet in
            guard let address = AppConfig.donationAddresses.first(where: { $0.key == wallet.token.blockchainType })?.value else {
                return
            }

            if let module = SendModule.controller(wallet: wallet, mode: .predefined(address: address)) {
                viewController?.navigationController?.pushViewController(module, animated: true)
            }
        }

        return ThemeNavigationController(rootViewController: viewController)
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
            case let .loaded(elements): return "loaded: \(elements.count) elements"
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
            case let .wallet(wallet): return wallet.coin.code
            case let .cexAsset(cexAsset): return cexAsset.coinCode
            }
        }

        var coin: Coin? {
            switch self {
            case let .wallet(wallet): return wallet.coin
            case let .cexAsset(cexAsset): return cexAsset.coin
            }
        }

        var wallet: Wallet? {
            switch self {
            case let .wallet(wallet): return wallet
            default: return nil
            }
        }

        var cexAsset: CexAsset? {
            switch self {
            case let .cexAsset(cexAsset): return cexAsset
            default: return nil
            }
        }

        var decimals: Int {
            switch self {
            case let .wallet(wallet): return wallet.decimals
            case .cexAsset: return 8 // TODO: how many decimals for coin???
            }
        }

        var priceCoinUid: String? {
            switch self {
            case let .wallet(wallet): return wallet.token.isCustom ? nil : wallet.coin.uid
            case let .cexAsset(cexAsset): return cexAsset.coin?.uid
            }
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case let .wallet(wallet):
                hasher.combine(wallet)
            case let .cexAsset(cexAsset):
                hasher.combine(cexAsset)
            }
        }

        static func == (lhs: Element, rhs: Element) -> Bool {
            switch (lhs, rhs) {
            case let (.wallet(lhsWallet), .wallet(rhsWallet)): return lhsWallet == rhsWallet
            case let (.cexAsset(lhsCexAsset), .cexAsset(rhsCexAsset)): return lhsCexAsset == rhsCexAsset
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

    class HeaderViewItem {
        let amount: String?
        let amountExpired: Bool
        let convertedValue: String?
        let convertedValueExpired: Bool
        let buttons: [WalletModule.Button: ButtonState]

        init(amount: String?, amountExpired: Bool, convertedValue: String?, convertedValueExpired: Bool, buttons: [WalletModule.Button: ButtonState]) {
            self.amount = amount
            self.amountExpired = amountExpired
            self.convertedValue = convertedValue
            self.convertedValueExpired = convertedValueExpired
            self.buttons = buttons
        }
    }
}

import Foundation
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit
import StorageKit
import EvmKit
import HsToolKit

class WalletService {
    private let keySortType = "wallet-sort-type"

    private let adapterService: WalletAdapterService
    private let coinPriceService: WalletCoinPriceService
    private let cacheManager: EnabledWalletCacheManager
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let marketKit: MarketKit.Kit
    private let localStorage: StorageKit.ILocalStorage
    private let rateAppManager: RateAppManager
    private let balancePrimaryValueManager: BalancePrimaryValueManager
    private let balanceHiddenManager: BalanceHiddenManager
    private let balanceConversionManager: BalanceConversionManager
    private let feeCoinProvider: FeeCoinProvider
    private let reachabilityManager: IReachabilityManager
    private let sorter = WalletSorter()
    private let disposeBag = DisposeBag()
    private var walletDisposeBag = DisposeBag()

    private let activeAccountRelay = PublishRelay<Account?>()
    private let accountsLostRelay = PublishRelay<()>()

    private let totalItemRelay = PublishRelay<TotalItem?>()
    private(set) var totalItem: TotalItem? {
        didSet {
            totalItemRelay.accept(totalItem)
        }
    }

    private let itemUpdatedRelay = PublishRelay<Item>()

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    private(set) var allItems: [Item] = [] {
        didSet {
            let hideZeroBalances = accountManager.activeAccount?.type.hideZeroBalances ?? false

            if hideZeroBalances {
                items = allItems.filter { $0.balanceData.balanceTotal != 0 }
            } else {
                items = allItems
            }
        }
    }

    private let sortTypeRelay = PublishRelay<WalletModule.SortType>()
    var sortType: WalletModule.SortType {
        didSet {
            sortTypeRelay.accept(sortType)
            handleUpdateSortType()
            localStorage.set(value: sortType.rawValue, for: keySortType)
        }
    }

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.wallet-service", qos: .userInitiated)

    init(adapterService: WalletAdapterService, coinPriceService: WalletCoinPriceService, cacheManager: EnabledWalletCacheManager, accountManager: AccountManager, walletManager: WalletManager, marketKit: MarketKit.Kit, localStorage: StorageKit.ILocalStorage, rateAppManager: RateAppManager, balancePrimaryValueManager: BalancePrimaryValueManager, balanceHiddenManager: BalanceHiddenManager, balanceConversionManager: BalanceConversionManager, appManager: IAppManager, feeCoinProvider: FeeCoinProvider, reachabilityManager: IReachabilityManager) {
        self.adapterService = adapterService
        self.coinPriceService = coinPriceService
        self.cacheManager = cacheManager
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.marketKit = marketKit
        self.localStorage = localStorage
        self.rateAppManager = rateAppManager
        self.balancePrimaryValueManager = balancePrimaryValueManager
        self.balanceHiddenManager = balanceHiddenManager
        self.balanceConversionManager = balanceConversionManager
        self.feeCoinProvider = feeCoinProvider
        self.reachabilityManager = reachabilityManager

        if let rawValue: String = localStorage.value(for: keySortType), let sortType = WalletModule.SortType(rawValue: rawValue) {
            self.sortType = sortType
        } else if let rawValue: Int = localStorage.value(for: "balance_sort_key"), rawValue < WalletModule.SortType.allCases.count {
            // todo: temp solution for restoring from version 0.22
            sortType = WalletModule.SortType.allCases[rawValue]
        } else {
            sortType = .balance
        }

        subscribe(disposeBag, accountManager.activeAccountObservable) { [weak self] in
            self?.activeAccountRelay.accept($0)
        }
        subscribe(disposeBag, accountManager.accountUpdatedObservable) { [weak self] in
            self?.handleUpdated(account: $0)
        }
        subscribe(disposeBag, accountManager.accountsLostObservable) { [weak self] isAccountsLost in
            if isAccountsLost {
                self?.accountsLostRelay.accept(())
            }
        }
        subscribe(disposeBag, walletManager.activeWalletsUpdatedObservable) { [weak self] in
            self?.sync(wallets: $0)
        }
        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in
            self?.coinPriceService.refresh()
        }
        subscribe(disposeBag, balanceConversionManager.conversionTokenObservable) { [weak self] _ in
            self?.syncTotalItem()
        }

        _sync(wallets: walletManager.activeWallets)
    }

    private func handleUpdated(account: Account) {
        if account.id == accountManager.activeAccount?.id {
            activeAccountRelay.accept(account)
        }
    }

    private func handleUpdateSortType() {
        queue.async {
            self.allItems = self.sorter.sort(items: self.allItems, sortType: self.sortType)
        }
    }

    private func sync(wallets: [Wallet]) {
        queue.async { self._sync(wallets: wallets) }
    }

    private func _sync(wallets: [Wallet]) {
        let cacheContainer = accountManager.activeAccount.map { cacheManager.cacheContainer(accountId: $0.id) }
        let priceItemMap = coinPriceService.itemMap(tokens: wallets.map { $0.token })

        let items: [Item] = wallets.map { wallet in
            let item = Item(
                    wallet: wallet,
                    isMainNet: adapterService.isMainNet(wallet: wallet) ?? fallbackIsMainNet,
                    balanceData: adapterService.balanceData(wallet: wallet) ?? cacheContainer?.balanceData(wallet: wallet) ?? fallbackBalanceData,
                    state: adapterService.state(wallet: wallet)  ?? fallbackAdapterState
            )

            item.priceItem = priceItemMap[wallet.coin.uid]

            return item
        }

        allItems = sorter.sort(items: items, sortType: sortType)
        syncTotalItem()

        let tokens = Set(wallets.map { $0.token })
        let feeCoinTokens = Set(wallets.compactMap { feeCoinProvider.feeToken(token: $0.token) })

        coinPriceService.set(tokens: tokens.union(feeCoinTokens).union(balanceConversionManager.conversionTokens))
    }

    private func items(coinUid: String) -> [Item] {
        allItems.filter { $0.wallet.coin.uid == coinUid }
    }

    private func syncTotalItem() {
        var total: Decimal = 0
        var expired = false

        items.forEach { item in
            if let rateItem = item.priceItem {
                total += item.balanceData.balanceTotal * rateItem.price.value

                if rateItem.expired {
                    expired = true
                }
            }

            if case .synced = item.state {
                // do nothing
            } else {
                expired = true
            }
        }

        var convertedValue: CoinValue?
        var convertedValueExpired = false

        if let conversionToken = balanceConversionManager.conversionToken, let priceItem = coinPriceService.item(token: conversionToken) {
            convertedValue = CoinValue(kind: .token(token: conversionToken), value: total / priceItem.price.value)
            convertedValueExpired = priceItem.expired
        }

        totalItem = TotalItem(
                currencyValue: CurrencyValue(currency: coinPriceService.currency, value: total),
                expired: expired,
                convertedValue: convertedValue,
                convertedValueExpired: expired || convertedValueExpired
        )
    }

    private func _item(wallet: Wallet) -> Item? {
        allItems.first { $0.wallet == wallet }
    }

    private var fallbackIsMainNet: Bool {
        true
    }

    private var fallbackBalanceData: BalanceData {
        BalanceData(balance: 0)
    }

    private var fallbackAdapterState: AdapterState {
        .syncing(progress: nil, lastBlockDate: nil)
    }

}

extension WalletService: IWalletAdapterServiceDelegate {

    func didPrepareAdapters() {
        queue.async {
            var balanceDataMap = [Wallet: BalanceData]()

            for item in self.allItems {
                let balanceData = self.adapterService.balanceData(wallet: item.wallet) ?? self.fallbackBalanceData

                item.isMainNet = self.adapterService.isMainNet(wallet: item.wallet) ?? self.fallbackIsMainNet
                item.balanceData = balanceData
                item.state = self.adapterService.state(wallet: item.wallet) ?? self.fallbackAdapterState

                balanceDataMap[item.wallet] = balanceData
            }

            self.allItems = self.sorter.sort(items: self.allItems, sortType: self.sortType)
            self.syncTotalItem()

            self.cacheManager.set(balanceDataMap: balanceDataMap)
        }
    }

    func didUpdate(isMainNet: Bool, wallet: Wallet) {
        queue.async {
            guard let item = self._item(wallet: wallet) else {
                return
            }

            item.isMainNet = isMainNet

            self.itemUpdatedRelay.accept(item)
        }
    }

    func didUpdate(balanceData: BalanceData, wallet: Wallet) {
        queue.async {
            guard let item = self._item(wallet: wallet) else {
                return
            }

            item.balanceData = balanceData

            if self.sortType == .balance, self.allItems.allSatisfy({ $0.state.isSynced }) {
                self.allItems = self.sorter.sort(items: self.allItems, sortType: self.sortType)
            } else {
                self.itemUpdatedRelay.accept(item)
            }

            self.syncTotalItem()

            self.cacheManager.set(balanceData: balanceData, wallet: wallet)
        }
    }

    func didUpdate(state: AdapterState, wallet: Wallet) {
        queue.async {
            guard let item = self._item(wallet: wallet) else {
                return
            }

            let oldState = item.state
            item.state = state

            if self.sortType == .balance, self.allItems.allSatisfy({ $0.state.isSynced }) {
                self.allItems = self.sorter.sort(items: self.allItems, sortType: self.sortType)
            } else {
                self.itemUpdatedRelay.accept(item)
            }

            if oldState.isSynced != state.isSynced {
                self.syncTotalItem()
            }
        }
    }

}

extension WalletService: IWalletCoinPriceServiceDelegate {

    private func handleUpdated(priceItemMap: [String: WalletCoinPriceService.Item]) {
        for item in allItems {
            item.priceItem = priceItemMap[item.wallet.coin.uid]
        }

        allItems = sorter.sort(items: allItems, sortType: sortType)
        syncTotalItem()
    }

    func didUpdateBaseCurrency() {
        queue.async {
            self.handleUpdated(priceItemMap: self.coinPriceService.itemMap(tokens: self.allItems.map { $0.wallet.token }))
        }
    }

    func didUpdate(itemsMap: [String: WalletCoinPriceService.Item]) {
        queue.async {
            self.handleUpdated(priceItemMap: itemsMap)
        }
    }

}

extension WalletService {

    var activeAccountObservable: Observable<Account?> {
        activeAccountRelay.asObservable()
    }

    var balanceHiddenObservable: Observable<Bool> {
        balanceHiddenManager.balanceHiddenObservable
    }

    var accountsLostObservable: Observable<()> {
        accountsLostRelay.asObservable()
    }

    var totalItemObservable: Observable<TotalItem?> {
        totalItemRelay.asObservable()
    }

    var itemUpdatedObservable: Observable<Item> {
        itemUpdatedRelay.asObservable()
    }

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var sortTypeObservable: Observable<WalletModule.SortType> {
        sortTypeRelay.asObservable()
    }

    var balancePrimaryValueObservable: Observable<BalancePrimaryValue> {
        balancePrimaryValueManager.balancePrimaryValueObservable
    }

    var balancePrimaryValue: BalancePrimaryValue {
        balancePrimaryValueManager.balancePrimaryValue
    }

    var balanceHidden: Bool {
        balanceHiddenManager.balanceHidden
    }

    var watchAccount: Bool {
        accountManager.activeAccount?.watchAccount ?? false
    }

    var activeAccount: Account? {
        accountManager.activeAccount
    }

    var isReachable: Bool {
        reachabilityManager.isReachable
    }

    var lastCreatedAccount: Account? {
        accountManager.popLastCreatedAccount()
    }

    func item(wallet: Wallet) -> Item? {
        queue.sync { _item(wallet: wallet) }
    }

    func notifyAppear() {
        rateAppManager.onBalancePageAppear()
    }

    func notifyDisappear() {
        rateAppManager.onBalancePageDisappear()
    }

    func refresh() {
        adapterService.refresh()
        coinPriceService.refresh()
    }

    func disable(wallet: Wallet) {
        walletManager.delete(wallets: [wallet])
    }

    func toggleBalanceHidden() {
        balanceHiddenManager.toggleBalanceHidden()
    }

    func toggleConversionCoin() {
        balanceConversionManager.toggleConversionToken()
    }

}

extension WalletService {

    class Item {
        let wallet: Wallet

        var isMainNet: Bool
        var balanceData: BalanceData
        var state: AdapterState
        var priceItem: WalletCoinPriceService.Item?

        init(wallet: Wallet, isMainNet: Bool, balanceData: BalanceData, state: AdapterState) {
            self.wallet = wallet
            self.isMainNet = isMainNet
            self.balanceData = balanceData
            self.state = state
        }
    }

    struct TotalItem {
        let currencyValue: CurrencyValue
        let expired: Bool
        let convertedValue: CoinValue?
        let convertedValueExpired: Bool
    }

}

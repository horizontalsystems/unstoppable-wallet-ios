import RxSwift
import RxRelay
import MarketKit
import CurrencyKit
import StorageKit
import EthereumKit

class WalletService {
    private let keyBalanceHidden = "wallet-balance-hidden"
    private let keySortType = "wallet-sort-type"

    private let adapterService: WalletAdapterService
    private let coinPriceService: WalletCoinPriceService
    private let cacheManager: EnabledWalletCacheManager
    private let accountManager: IAccountManager
    private let walletManager: WalletManager
    private let localStorage: StorageKit.ILocalStorage
    private let rateAppManager: IRateAppManager
    private let feeCoinProvider: FeeCoinProvider
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
            if watchAccount {
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

    private let balanceHiddenRelay = PublishRelay<Bool>()
    var balanceHidden: Bool {
        didSet {
            balanceHiddenRelay.accept(balanceHidden)
            localStorage.set(value: balanceHidden, for: keyBalanceHidden)
        }
    }

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.wallet-service", qos: .userInitiated)

    init(adapterService: WalletAdapterService, coinPriceService: WalletCoinPriceService, cacheManager: EnabledWalletCacheManager, accountManager: IAccountManager, walletManager: WalletManager, localStorage: StorageKit.ILocalStorage, rateAppManager: IRateAppManager, appManager: IAppManager, feeCoinProvider: FeeCoinProvider) {
        self.adapterService = adapterService
        self.coinPriceService = coinPriceService
        self.cacheManager = cacheManager
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.localStorage = localStorage
        self.rateAppManager = rateAppManager
        self.feeCoinProvider = feeCoinProvider

        if let rawValue: String = localStorage.value(for: keySortType), let sortType = WalletModule.SortType(rawValue: rawValue) {
            self.sortType = sortType
        } else if let rawValue: Int = localStorage.value(for: "balance_sort_key"), rawValue < WalletModule.SortType.allCases.count {
            // todo: temp solution for restoring from version 0.22
            sortType = WalletModule.SortType.allCases[rawValue]
        } else {
            sortType = .balance
        }

        if let balanceHidden: Bool = localStorage.value(for: keyBalanceHidden) {
            self.balanceHidden = balanceHidden
        } else if let balanceHidden: Bool = localStorage.value(for: "balance_hidden") {
            // todo: temp solution for restoring from version 0.22
            self.balanceHidden = balanceHidden
        } else {
            balanceHidden = false
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
        let priceItemMap = coinPriceService.itemMap(coinUids: wallets.map { $0.coin.uid })

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

        let coinUids = Set(wallets.filter { !$0.coin.isCustom }.map { $0.coin.uid })
        let feeCoinUids = Set(wallets.compactMap { feeCoinProvider.feeCoin(coinType: $0.coinType)?.coin.uid })
        coinPriceService.set(coinUids: coinUids.union(feeCoinUids))
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

        totalItem = TotalItem(amount: total, currency: coinPriceService.currency, expired: expired)
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

extension WalletService: IWalletRateServiceDelegate {

    private func handleUpdated(priceItemMap: [String: WalletCoinPriceService.Item]) {
        for item in allItems {
            item.priceItem = priceItemMap[item.wallet.coin.uid]
        }

        allItems = sorter.sort(items: allItems, sortType: sortType)
        syncTotalItem()
    }

    func didUpdateBaseCurrency() {
        queue.async {
            self.handleUpdated(priceItemMap: self.coinPriceService.itemMap(coinUids: self.allItems.map { $0.wallet.coin.uid }))
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
        balanceHiddenRelay.asObservable()
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

    var watchAccount: Bool {
        accountManager.activeAccount?.watchAccount ?? false
    }

    var watchAccountAddress: EthereumKit.Address? {
        guard let account = accountManager.activeAccount else {
            return nil
        }

        switch account.type {
        case .address(let address): return address
        default: return nil
        }
    }

    var activeAccount: Account? {
        accountManager.activeAccount
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
        let amount: Decimal
        let currency: Currency
        let expired: Bool
    }

}

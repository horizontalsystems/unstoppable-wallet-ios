import RxSwift
import RxRelay
import CoinKit
import CurrencyKit

class WalletService {
    private let adapterService: WalletAdapterService
    private let rateService: WalletRateService
    private let cacheManager: EnabledWalletCacheManager
    private let accountManager: IAccountManager
    private let walletManager: WalletManager
    private let localStorage: ILocalStorage
    private let rateAppManager: IRateAppManager
    private let feeCoinProvider: IFeeCoinProvider
    private let sorter = WalletSorter()
    private let disposeBag = DisposeBag()
    private var walletDisposeBag = DisposeBag()

    private let activeAccountRelay = PublishRelay<Account?>()
    private let balanceHiddenRelay = PublishRelay<Bool>()
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

    private var sortType: SortType

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.wallet-service", qos: .userInitiated)

    init(adapterService: WalletAdapterService, rateService: WalletRateService, cacheManager: EnabledWalletCacheManager, accountManager: IAccountManager, walletManager: WalletManager, sortTypeManager: ISortTypeManager, localStorage: ILocalStorage, rateAppManager: IRateAppManager, feeCoinProvider: IFeeCoinProvider) {
        self.adapterService = adapterService
        self.rateService = rateService
        self.cacheManager = cacheManager
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.localStorage = localStorage
        self.rateAppManager = rateAppManager
        self.feeCoinProvider = feeCoinProvider

        sortType = sortTypeManager.sortType

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
        subscribe(disposeBag, sortTypeManager.sortTypeObservable) { [weak self] in
            self?.handleUpdate(sortType: $0)
        }

        _sync(wallets: walletManager.activeWallets)
    }

    private func handleUpdated(account: Account) {
        if account.id == accountManager.activeAccount?.id {
            activeAccountRelay.accept(account)
        }
    }

    private func handleUpdate(sortType: SortType) {
        queue.async {
            self.sortType = sortType
            self.items = self.sorter.sort(items: self.items, sort: self.sortType)
        }
    }

    private func sync(wallets: [Wallet]) {
        queue.async { self._sync(wallets: wallets) }
    }

    private func _sync(wallets: [Wallet]) {
        let cacheContainer = accountManager.activeAccount.map { cacheManager.cacheContainer(accountId: $0.id) }
        let rateItemMap = rateService.itemMap(coinTypes: wallets.map { $0.coin.type })

        let items: [Item] = wallets.map { wallet in
            let item = Item(
                    wallet: wallet,
                    isMainNet: adapterService.isMainNet(wallet: wallet) ?? fallbackIsMainNet,
                    balanceData: adapterService.balanceData(wallet: wallet) ?? cacheContainer?.balanceData(wallet: wallet) ?? fallbackBalanceData,
                    state: adapterService.state(wallet: wallet)  ?? fallbackAdapterState
            )

            item.rateItem = rateItemMap[wallet.coin.type]

            return item
        }

        self.items = sorter.sort(items: items, sort: sortType)
        syncTotalItem()

        let coinTypes = Set(wallets.map { $0.coin.type })
        let feeCoinTypes = Set(wallets.compactMap { feeCoinProvider.feeCoin(coin: $0.coin)?.type })
        rateService.set(coinTypes: Array(coinTypes.union(feeCoinTypes)))
    }

    private func items(coinType: CoinType) -> [Item] {
        items.filter { $0.wallet.coin.type == coinType }
    }

    private func syncTotalItem() {
        var total: Decimal = 0
        var expired = false

        items.forEach { item in
            if let rateItem = item.rateItem {
                total += item.balanceData.balanceTotal * rateItem.rate.value

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

        totalItem = TotalItem(amount: total, currency: rateService.currency, expired: expired)
    }

    private func _item(wallet: Wallet) -> Item? {
        items.first { $0.wallet == wallet }
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

            for item in self.items {
                let balanceData = self.adapterService.balanceData(wallet: item.wallet) ?? self.fallbackBalanceData

                item.isMainNet = self.adapterService.isMainNet(wallet: item.wallet) ?? self.fallbackIsMainNet
                item.balanceData = balanceData
                item.state = self.adapterService.state(wallet: item.wallet) ?? self.fallbackAdapterState

                balanceDataMap[item.wallet] = balanceData
            }

            self.items = self.sorter.sort(items: self.items, sort: self.sortType)
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

            self.itemUpdatedRelay.accept(item)
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

            self.itemUpdatedRelay.accept(item)

            if oldState.isSynced != state.isSynced {
                self.syncTotalItem()
            }
        }
    }

}

extension WalletService: IWalletRateServiceDelegate {

    func didUpdateBaseCurrency() {
        queue.async {
            let rateItemMap = self.rateService.itemMap(coinTypes: self.items.map { $0.wallet.coin.type })

            for item in self.items {
                item.rateItem = rateItemMap[item.wallet.coin.type]
            }

            self.items = self.sorter.sort(items: self.items, sort: self.sortType)
            self.syncTotalItem()
        }
    }

    func didUpdate(itemsMap: [CoinType: WalletRateService.Item]) {
        queue.async {
            for (coinType, rateItem) in itemsMap {
                for item in self.items(coinType: coinType) {
                    item.rateItem = rateItem
                    self.itemUpdatedRelay.accept(item)
                }
            }

            self.syncTotalItem()
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

    var activeAccount: Account? {
        accountManager.activeAccount
    }

    var balanceHidden: Bool {
        localStorage.balanceHidden
    }

    func item(wallet: Wallet) -> Item? {
        queue.sync { _item(wallet: wallet) }
    }

    func toggleBalanceHidden() {
        let newBalanceHidden = !balanceHidden
        localStorage.balanceHidden = newBalanceHidden
        balanceHiddenRelay.accept(newBalanceHidden)
    }

    func notifyAppear() {
        rateAppManager.onBalancePageAppear()
    }

    func notifyDisappear() {
        rateAppManager.onBalancePageDisappear()
    }

    func refresh() {
        adapterService.refresh()
        rateService.refresh()
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
        var rateItem: WalletRateService.Item?

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

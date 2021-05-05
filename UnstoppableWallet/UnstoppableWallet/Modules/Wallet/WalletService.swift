import RxSwift
import RxRelay
import CoinKit
import CurrencyKit

class WalletService {
    private let adapterService: WalletAdapterService
    private let rateService: WalletRateService
    private let accountManager: IAccountManager
    private let walletManager: IWalletManager
    private let sortTypeManager: ISortTypeManager
    private let localStorage: ILocalStorage
    private let rateAppManager: IRateAppManager
    private let feeCoinProvider: IFeeCoinProvider
    private let sorter = WalletSorter()
    private let disposeBag = DisposeBag()

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

    init(adapterService: WalletAdapterService, rateService: WalletRateService, accountManager: IAccountManager, walletManager: IWalletManager, sortTypeManager: ISortTypeManager, localStorage: ILocalStorage, rateAppManager: IRateAppManager, feeCoinProvider: IFeeCoinProvider, scheduler: ImmediateSchedulerType) {
        self.adapterService = adapterService
        self.rateService = rateService
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.sortTypeManager = sortTypeManager
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
        subscribe(scheduler, disposeBag, walletManager.activeWalletsUpdatedObservable) { [weak self] in
            self?.sync(wallets: $0)
        }
        subscribe(scheduler, disposeBag, sortTypeManager.sortTypeObservable) { [weak self] in
            self?.handleUpdate(sortType: $0)
        }

        sync(wallets: walletManager.activeWallets)
    }

    private func handleUpdated(account: Account) {
        if account.id == accountManager.activeAccount?.id {
            activeAccountRelay.accept(account)
        }
    }

    private func handleUpdate(sortType: SortType) {
        self.sortType = sortType
        items = sorter.sort(items: items, sort: sortType)
    }

    private func sync(wallets: [Wallet]) {
        let items: [Item] = wallets.map { wallet in
            let item = Item(wallet: wallet)

            item.balance = adapterService.balance(wallet: wallet)
            item.balanceLocked = adapterService.balanceLocked(wallet: wallet)
            item.state = adapterService.state(wallet: wallet)
            item.rateItem = rateService.item(coinType: wallet.coin.type)

            return item
        }

        self.items = sorter.sort(items: items, sort: sortType)
        syncTotalItem()

        adapterService.set(wallets: wallets)

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
            if let balanceTotal = item.balanceTotal, let rateItem = item.rateItem {
                total += balanceTotal * rateItem.rate.value

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

}

extension WalletService: IWalletAdapterServiceDelegate {

    func didPrepareAdapters() {
        for item in items {
            item.balance = adapterService.balance(wallet: item.wallet)
            item.balanceLocked = adapterService.balanceLocked(wallet: item.wallet)
            item.state = adapterService.state(wallet: item.wallet)
        }

        items = sorter.sort(items: items, sort: sortType)
        syncTotalItem()
    }

    func didUpdate(balance: Decimal, balanceLocked: Decimal?, wallet: Wallet) {
        guard let item = item(wallet: wallet) else {
            return
        }

        item.balance = balance
        item.balanceLocked = balanceLocked

        itemUpdatedRelay.accept(item)
        syncTotalItem()
    }

    func didUpdate(state: AdapterState, wallet: Wallet) {
        guard let item = item(wallet: wallet) else {
            return
        }

        let oldState = item.state
        item.state = state

        itemUpdatedRelay.accept(item)

        if oldState?.isSynced != state.isSynced {
            syncTotalItem()
        }
    }

}

extension WalletService: IWalletRateServiceDelegate {

    func didUpdateBaseCurrency() {
        for item in items {
            item.rateItem = rateService.item(coinType: item.wallet.coin.type)
        }

        items = sorter.sort(items: items, sort: sortType)
        syncTotalItem()
    }

    func didUpdate(itemsMap: [CoinType: WalletRateService.Item]) {
        for (coinType, rateItem) in itemsMap {
            for item in items(coinType: coinType) {
                item.rateItem = rateItem
                itemUpdatedRelay.accept(item)
            }
        }

        syncTotalItem()
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
        items.first { $0.wallet == wallet }
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

}

extension WalletService {

    class Item {
        let wallet: Wallet

        var balance: Decimal?
        var balanceLocked: Decimal?
        var state: AdapterState?
        var rateItem: WalletRateService.Item?

        init(wallet: Wallet) {
            self.wallet = wallet
        }

        var balanceTotal: Decimal? {
            guard let balance = balance else {
                return nil
            }

            return balance + (balanceLocked ?? 0)
        }
    }

    struct TotalItem {
        let amount: Decimal
        let currency: Currency
        let expired: Bool
    }

}

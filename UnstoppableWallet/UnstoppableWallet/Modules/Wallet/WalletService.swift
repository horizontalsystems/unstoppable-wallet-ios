import Foundation
import RxSwift
import RxRelay
import HsToolKit
import StorageKit
import CurrencyKit

protocol IWalletElementService: AnyObject {
    var elements: [WalletModule.Element] { get }
    func isMainNet(element: WalletModule.Element) -> Bool?
    func balanceData(element: WalletModule.Element) -> BalanceData?
    func state(element: WalletModule.Element) -> AdapterState?
    func refresh()
    func disable(element: WalletModule.Element)
}

protocol IWalletElementServiceDelegate: AnyObject {
    func didUpdate(elements: [WalletModule.Element])
    func didUpdateElements()
    func didUpdate(isMainNet: Bool, element: WalletModule.Element)
    func didUpdate(balanceData: BalanceData, element: WalletModule.Element)
    func didUpdate(state: AdapterState, element: WalletModule.Element)
}

class WalletService {
    private let keySortType = "wallet-sort-type"

    private let elementService: IWalletElementService
    private let coinPriceService: WalletCoinPriceService
    private let accountManager: AccountManager
    private let cacheManager: EnabledWalletCacheManager
    private let accountRestoreWarningManager: AccountRestoreWarningManager
    private let reachabilityManager: IReachabilityManager
    private let balancePrimaryValueManager: BalancePrimaryValueManager
    private let balanceHiddenManager: BalanceHiddenManager
    private let balanceConversionManager: BalanceConversionManager
    private let cloudAccountBackupManager: CloudAccountBackupManager
    private let rateAppManager: RateAppManager
    private let feeCoinProvider: FeeCoinProvider
    private let localStorage: StorageKit.ILocalStorage
    private let sorter = WalletSorter()
    private let disposeBag = DisposeBag()

    private let activeAccountRelay = PublishRelay<Account?>()
    private let accountsLostRelay = PublishRelay<()>()

    private let sortTypeRelay = PublishRelay<WalletModule.SortType>()
    var sortType: WalletModule.SortType {
        didSet {
            sortTypeRelay.accept(sortType)
            handleUpdateSortType()
            localStorage.set(value: sortType.rawValue, for: keySortType)
        }
    }

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

    private var internalItems: [Item] = [] {
        didSet {
            let hideZeroBalances = activeAccount?.type.hideZeroBalances ?? false

            if hideZeroBalances {
                items = internalItems.filter { $0.balanceData.balanceTotal != 0 || $0.element.wallet?.token.type == .native }
            } else {
                items = internalItems
            }
        }
    }

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.wallet-service", qos: .userInitiated)

    init(elementService: IWalletElementService, coinPriceService: WalletCoinPriceService, accountManager: AccountManager,
         cacheManager: EnabledWalletCacheManager, accountRestoreWarningManager: AccountRestoreWarningManager, reachabilityManager: IReachabilityManager,
         balancePrimaryValueManager: BalancePrimaryValueManager, balanceHiddenManager: BalanceHiddenManager, balanceConversionManager: BalanceConversionManager,
         cloudAccountBackupManager: CloudAccountBackupManager, rateAppManager: RateAppManager, appManager: IAppManager, feeCoinProvider: FeeCoinProvider,
         localStorage: StorageKit.ILocalStorage
    ) {
        self.elementService = elementService
        self.coinPriceService = coinPriceService
        self.accountManager = accountManager
        self.cacheManager = cacheManager
        self.accountRestoreWarningManager = accountRestoreWarningManager
        self.reachabilityManager = reachabilityManager
        self.balancePrimaryValueManager = balancePrimaryValueManager
        self.balanceHiddenManager = balanceHiddenManager
        self.balanceConversionManager = balanceConversionManager
        self.cloudAccountBackupManager = cloudAccountBackupManager
        self.rateAppManager = rateAppManager
        self.feeCoinProvider = feeCoinProvider
        self.localStorage = localStorage

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
        subscribe(disposeBag, accountManager.accountDeletedObservable) { [weak self] in
            self?.handleDeleted(account: $0)
        }
        subscribe(disposeBag, accountManager.accountsLostObservable) { [weak self] isAccountsLost in
            if isAccountsLost {
                self?.accountsLostRelay.accept(())
            }
        }
        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in
            self?.coinPriceService.refresh()
        }
        subscribe(disposeBag, balanceConversionManager.conversionTokenObservable) { [weak self] _ in
            self?.syncTotalItem()
        }

        _sync(elements: elementService.elements)
    }

    private func _sync(elements: [WalletModule.Element]) {
        let cacheContainer = activeAccount.map { cacheManager.cacheContainer(accountId: $0.id) }
        let priceItemMap = coinPriceService.itemMap(coinUids: elements.compactMap { $0.priceCoinUid })
        let watchAccount = watchAccount

        let items: [Item] = elements.map { element in
            let item = Item(
                    element: element,
                    isMainNet: elementService.isMainNet(element: element) ?? fallbackIsMainNet,
                    watchAccount: watchAccount,
                    balanceData: elementService.balanceData(element: element) ?? cachedBalanceData(element: element, cacheContainer: cacheContainer) ?? fallbackBalanceData,
                    state: elementService.state(element: element)  ?? fallbackAdapterState
            )

            if let priceCoinUid = element.priceCoinUid {
                item.priceItem = priceItemMap[priceCoinUid]
            }

            return item
        }

        internalItems = sorter.sort(items: items, sortType: sortType)
        syncTotalItem()

        let coinUids = Set(elements.compactMap { $0.priceCoinUid })
        let feeCoinUids = Set(elements.compactMap { $0.wallet }.compactMap { feeCoinProvider.feeToken(token: $0.token) }.map { $0.coin.uid })

        coinPriceService.set(coinUids: coinUids.union(feeCoinUids).union(balanceConversionManager.conversionTokens.map { $0.coin.uid }))
    }

    private func cachedBalanceData(element: WalletModule.Element, cacheContainer: EnabledWalletCacheManager.CacheContainer?) -> BalanceData? {
        switch element {
        case .wallet(let wallet): return cacheContainer?.balanceData(wallet: wallet)
        default: return nil
        }
    }

    private func _item(element: WalletModule.Element) -> Item? {
        internalItems.first { $0.element == element }
    }

    private func handleUpdateSortType() {
        queue.async {
            self.internalItems = self.sorter.sort(items: self.internalItems, sortType: self.sortType)
        }
    }

    private func handleUpdated(account: Account) {
        if account.id == accountManager.activeAccount?.id {
            activeAccountRelay.accept(account)
        }
    }

    private func handleDeleted(account: Account) {
        accountRestoreWarningManager.removeIgnoreWarning(account: account)
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

        if let conversionToken = balanceConversionManager.conversionToken, let priceItem = coinPriceService.item(coinUid: conversionToken.coin.uid) {
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

extension WalletService: IWalletElementServiceDelegate {

    func didUpdate(elements: [WalletModule.Element]) {
        queue.async {
            self._sync(elements: elements)
        }
    }

    func didUpdateElements() {
        queue.async {
            var balanceDataMap = [Wallet: BalanceData]()

            for item in self.internalItems {
                let balanceData = self.elementService.balanceData(element: item.element) ?? self.fallbackBalanceData

                item.isMainNet = self.elementService.isMainNet(element: item.element) ?? self.fallbackIsMainNet
                item.balanceData = balanceData
                item.state = self.elementService.state(element: item.element) ?? self.fallbackAdapterState

                if let wallet = item.element.wallet {
                    balanceDataMap[wallet] = balanceData
                }
            }

            self.internalItems = self.sorter.sort(items: self.internalItems, sortType: self.sortType)
            self.syncTotalItem()

            if !balanceDataMap.isEmpty {
                self.cacheManager.set(balanceDataMap: balanceDataMap)
            }
        }
    }

    func didUpdate(isMainNet: Bool, element: WalletModule.Element) {
        queue.async {
            guard let item = self._item(element: element) else {
                return
            }

            item.isMainNet = isMainNet

            self.itemUpdatedRelay.accept(item)
        }
    }

    func didUpdate(balanceData: BalanceData, element: WalletModule.Element) {
        queue.async {
            guard let item = self._item(element: element) else {
                return
            }

            item.balanceData = balanceData

            if self.sortType == .balance, self.internalItems.allSatisfy({ $0.state.isSynced }) {
                self.internalItems = self.sorter.sort(items: self.internalItems, sortType: self.sortType)
            } else {
                self.itemUpdatedRelay.accept(item)
            }

            self.syncTotalItem()

            if let wallet = element.wallet {
                self.cacheManager.set(balanceData: balanceData, wallet: wallet)
            }
        }
    }

    func didUpdate(state: AdapterState, element: WalletModule.Element) {
        queue.async {
            guard let item = self._item(element: element) else {
                return
            }

            let oldState = item.state
            item.state = state

            if self.sortType == .balance, self.internalItems.allSatisfy({ $0.state.isSynced }) {
                self.internalItems = self.sorter.sort(items: self.internalItems, sortType: self.sortType)
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

    private func _handleUpdated(priceItemMap: [String: WalletCoinPriceService.Item]) {
        for item in internalItems {
            if let priceCoinUid = item.element.priceCoinUid {
                item.priceItem = priceItemMap[priceCoinUid]
            }
        }

        internalItems = sorter.sort(items: internalItems, sortType: sortType)
        syncTotalItem()
    }

    func didUpdateBaseCurrency() {
        queue.async {
            let coinUids = Array(Set(self.internalItems.compactMap { $0.element.priceCoinUid }))
            self._handleUpdated(priceItemMap: self.coinPriceService.itemMap(coinUids: coinUids))
        }
    }

    func didUpdate(itemsMap: [String: WalletCoinPriceService.Item]) {
        queue.async {
            self._handleUpdated(priceItemMap: itemsMap)
        }
    }

}

extension WalletService {

    var activeAccountObservable: Observable<Account?> {
        activeAccountRelay.asObservable()
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

    var accountsLostObservable: Observable<()> {
        accountsLostRelay.asObservable()
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

    var balanceHiddenObservable: Observable<Bool> {
        balanceHiddenManager.balanceHiddenObservable
    }

    var activeAccount: Account? {
        accountManager.activeAccount
    }

    var watchAccount: Bool {
        accountManager.activeAccount?.watchAccount ?? false
    }

    var lastCreatedAccount: Account? {
        accountManager.popLastCreatedAccount()
    }

    var balanceHidden: Bool {
        balanceHiddenManager.balanceHidden
    }

    var isReachable: Bool {
        reachabilityManager.isReachable
    }

    func item(element: WalletModule.Element) -> Item? {
        queue.sync {
            _item(element: element)
        }
    }

    func toggleConversionCoin() {
        balanceConversionManager.toggleConversionToken()
    }

    func toggleBalanceHidden() {
        balanceHiddenManager.toggleBalanceHidden()
    }

    func notifyAppear() {
        rateAppManager.onBalancePageAppear()
    }

    func notifyDisappear() {
        rateAppManager.onBalancePageDisappear()
    }

    func refresh() {
        elementService.refresh()
        coinPriceService.refresh()
    }

    func disable(element: WalletModule.Element) {
        elementService.disable(element: element)
    }

    func isCloudBackedUp(account: Account) -> Bool {
        cloudAccountBackupManager.backedUp(uniqueId: account.type.uniqueId())
    }

    func didIgnoreAccountWarning() {
        guard let account = accountManager.activeAccount, account.nonRecommended else {
            return
        }

        accountRestoreWarningManager.setIgnoreWarning(account: account)
        activeAccountRelay.accept(account)
    }

}

extension WalletService {

    class Item {
        let element: WalletModule.Element
        var isMainNet: Bool
        var watchAccount: Bool
        var balanceData: BalanceData
        var state: AdapterState
        var priceItem: WalletCoinPriceService.Item?

        init(element: WalletModule.Element, isMainNet: Bool, watchAccount: Bool, balanceData: BalanceData, state: AdapterState) {
            self.element = element
            self.isMainNet = isMainNet
            self.watchAccount = watchAccount
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

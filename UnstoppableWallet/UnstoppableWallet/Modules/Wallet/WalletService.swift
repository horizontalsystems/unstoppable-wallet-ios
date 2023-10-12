import Foundation
import Combine
import RxSwift
import RxRelay
import HsToolKit
import HsExtensions
import StorageKit
import CurrencyKit

protocol IWalletElementService: AnyObject {
    var delegate: IWalletElementServiceDelegate? { get set }
    var state: WalletModule.ElementState { get }
    func isMainNet(element: WalletModule.Element) -> Bool?
    func balanceData(element: WalletModule.Element) -> BalanceData?
    func state(element: WalletModule.Element) -> AdapterState?
    func refresh()
    func disable(element: WalletModule.Element)
}

protocol IWalletElementServiceDelegate: AnyObject {
    func didUpdate(elementState: WalletModule.ElementState, elementService: IWalletElementService)
    func didUpdateElements(elementService: IWalletElementService)
    func didUpdate(isMainNet: Bool, element: WalletModule.Element)
    func didUpdate(balanceData: BalanceData, element: WalletModule.Element)
    func didUpdate(state: AdapterState, element: WalletModule.Element)
}

class WalletService {
    private let keySortType = "wallet-sort-type"

    private let elementServiceFactory: WalletElementServiceFactory
    private let coinPriceService: WalletCoinPriceService
    private let accountManager: AccountManager
    private let cacheManager: EnabledWalletCacheManager
    private let accountRestoreWarningManager: AccountRestoreWarningManager
    private let reachabilityManager: IReachabilityManager
    private let balancePrimaryValueManager: BalancePrimaryValueManager
    private let balanceHiddenManager: BalanceHiddenManager
    private let balanceConversionManager: BalanceConversionManager
    private let cloudAccountBackupManager: CloudBackupManager
    private let rateAppManager: RateAppManager
    private let feeCoinProvider: FeeCoinProvider
    private let localStorage: StorageKit.ILocalStorage
    private let sorter = WalletSorter()
    private let disposeBag = DisposeBag()

    private var internalState: State = .loading {
        didSet {
            switch internalState {
            case .loaded(let items):
                let hideZeroBalances = activeAccount?.type.hideZeroBalances ?? false

                if hideZeroBalances {
                    state = .loaded(items: items.filter { $0.balanceData.balanceTotal != 0 || ($0.element.wallet?.token.type.isNative ?? false) })
                } else {
                    state = .loaded(items: items)
                }
            default:
                state = internalState
            }
        }
    }

    private var elementService: IWalletElementService?

    @PostPublished private(set) var state: State = .loading
    @PostPublished private(set) var totalItem: TotalItem?

    private let activeAccountRelay = PublishRelay<Account?>()
    private let accountsLostRelay = PublishRelay<()>()
    private let itemUpdatedRelay = PublishRelay<Item>()

    private let sortTypeRelay = PublishRelay<WalletModule.SortType>()
    var sortType: WalletModule.SortType {
        didSet {
            sortTypeRelay.accept(sortType)
            handleUpdateSortType()
            localStorage.set(value: sortType.rawValue, for: keySortType)
        }
    }


    private let queue = DispatchQueue(label: "\(AppConfig.label).wallet-service", qos: .userInitiated)

    init(elementServiceFactory: WalletElementServiceFactory, coinPriceService: WalletCoinPriceService, accountManager: AccountManager,
         cacheManager: EnabledWalletCacheManager, accountRestoreWarningManager: AccountRestoreWarningManager, reachabilityManager: IReachabilityManager,
         balancePrimaryValueManager: BalancePrimaryValueManager, balanceHiddenManager: BalanceHiddenManager, balanceConversionManager: BalanceConversionManager,
         cloudAccountBackupManager: CloudBackupManager, rateAppManager: RateAppManager, appManager: IAppManager, feeCoinProvider: FeeCoinProvider,
         localStorage: StorageKit.ILocalStorage
    ) {
        self.elementServiceFactory = elementServiceFactory
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
            self?.handleUpdated(activeAccount: $0)
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

        sync(activeAccount: accountManager.activeAccount)
    }

    private func sync(activeAccount: Account?) {
        elementService?.delegate = nil

        if let activeAccount {
            let elementService = elementServiceFactory.elementService(account: activeAccount)
            elementService.delegate = self
            self.elementService = elementService

            queue.async {
                self._sync(elementState: elementService.state, elementService: elementService)
            }
        } else {
            queue.async {
                self.internalState = .noAccount
            }
        }
    }

    private func _sync(elementState: WalletModule.ElementState, elementService: IWalletElementService) {
        switch elementState {
        case .loading:
            internalState = .loading
        case .loaded(let elements):
            let cacheContainer = activeAccount.map { cacheManager.cacheContainer(accountId: $0.id) }
            let priceItemMap = coinPriceService.itemMap(coinUids: elements.compactMap { $0.priceCoinUid })
            let watchAccount = watchAccount

            let items: [Item] = elements.map { element in
                let item = Item(
                        element: element,
                        isMainNet: elementService.isMainNet(element: element) ?? fallbackIsMainNet,
                        watchAccount: watchAccount,
                        balanceData: elementService.balanceData(element: element) ?? _cachedBalanceData(element: element, cacheContainer: cacheContainer) ?? fallbackBalanceData,
                        state: elementService.state(element: element)  ?? fallbackAdapterState
                )

                if let priceCoinUid = element.priceCoinUid {
                    item.priceItem = priceItemMap[priceCoinUid]
                }

                return item
            }

            internalState = .loaded(items: sorter.sort(items: items, sortType: sortType))
            _syncTotalItem()

            coinPriceService.set(
                    coinUids: Set(elements.compactMap { $0.priceCoinUid }),
                    feeCoinUids: Set(elements.compactMap { $0.wallet }.compactMap { feeCoinProvider.feeToken(token: $0.token) }.map { $0.coin.uid }),
                    conversionCoinUids: Set(balanceConversionManager.conversionTokens.map { $0.coin.uid })
            )
        case .failed(let reason):
            internalState = .failed(reason: reason)
        }
    }

    private func _cachedBalanceData(element: WalletModule.Element, cacheContainer: EnabledWalletCacheManager.CacheContainer?) -> BalanceData? {
        switch element {
        case .wallet(let wallet): return cacheContainer?.balanceData(wallet: wallet)
        default: return nil
        }
    }

    private func _sorted(items: [Item]) -> [Item] {
        sorter.sort(items: items, sortType: sortType)
    }

    private func _item(element: WalletModule.Element, items: [Item]) -> Item? {
        items.first { $0.element == element }
    }

    private func handleUpdated(activeAccount: Account?) {
        queue.async {
            self.sync(activeAccount: activeAccount)
        }

        activeAccountRelay.accept(activeAccount)
    }

    private func handleUpdateSortType() {
        queue.async {
            guard case .loaded(let items) = self.internalState else {
                return
            }

            self.internalState = .loaded(items: self._sorted(items: items))
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
        queue.async {
            self._syncTotalItem()
        }
    }

    private func _syncTotalItem() {
        guard case .loaded(let items) = state else {
            return
        }

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
        BalanceData(available: 0)
    }

    private var fallbackAdapterState: AdapterState {
        .syncing(progress: nil, lastBlockDate: nil)
    }

}

extension WalletService: IWalletElementServiceDelegate {

    func didUpdate(elementState: WalletModule.ElementState, elementService: IWalletElementService) {
        queue.async {
            self._sync(elementState: elementState, elementService: elementService)
        }
    }

    func didUpdateElements(elementService: IWalletElementService) {
        queue.async {
            guard case .loaded(let items) = self.internalState else {
                return
            }

            var balanceDataMap = [Wallet: BalanceData]()

            for item in items {
                let balanceData = elementService.balanceData(element: item.element) ?? self.fallbackBalanceData

                item.isMainNet = elementService.isMainNet(element: item.element) ?? self.fallbackIsMainNet
                item.balanceData = balanceData
                item.state = elementService.state(element: item.element) ?? self.fallbackAdapterState

                if let wallet = item.element.wallet {
                    balanceDataMap[wallet] = balanceData
                }
            }

            self.internalState = .loaded(items: self._sorted(items: items))
            self._syncTotalItem()

            if !balanceDataMap.isEmpty {
                self.cacheManager.set(balanceDataMap: balanceDataMap)
            }
        }
    }

    func didUpdate(isMainNet: Bool, element: WalletModule.Element) {
        queue.async {
            guard case .loaded(let items) = self.internalState, let item = self._item(element: element, items: items) else {
                return
            }

            item.isMainNet = isMainNet

            self.itemUpdatedRelay.accept(item)
        }
    }

    func didUpdate(balanceData: BalanceData, element: WalletModule.Element) {
        queue.async {
            guard case .loaded(let items) = self.internalState, let item = self._item(element: element, items: items) else {
                return
            }

            item.balanceData = balanceData

            if self.sortType == .balance, items.allSatisfy({ $0.state.isSynced }) {
                self.internalState = .loaded(items: self._sorted(items: items))
            } else {
                self.itemUpdatedRelay.accept(item)
            }

            self._syncTotalItem()

            if let wallet = element.wallet {
                self.cacheManager.set(balanceData: balanceData, wallet: wallet)
            }
        }
    }

    func didUpdate(state: AdapterState, element: WalletModule.Element) {
        queue.async {
            guard case .loaded(let items) = self.internalState, let item = self._item(element: element, items: items) else {
                return
            }

            let oldState = item.state
            item.state = state

            if self.sortType == .balance, items.allSatisfy({ $0.state.isSynced }) {
                self.internalState = .loaded(items: self._sorted(items: items))
            } else {
                self.itemUpdatedRelay.accept(item)
            }

            if oldState.isSynced != state.isSynced {
                self._syncTotalItem()
            }
        }
    }

}

extension WalletService: IWalletCoinPriceServiceDelegate {

    private func _handleUpdated(priceItemMap: [String: WalletCoinPriceService.Item], items: [Item]) {
        for item in items {
            if let priceCoinUid = item.element.priceCoinUid {
                item.priceItem = priceItemMap[priceCoinUid]
            }
        }

        internalState = .loaded(items: _sorted(items: items))
        _syncTotalItem()
    }

    func didUpdateBaseCurrency() {
        queue.async {
            guard case .loaded(let items) = self.internalState else {
                return
            }

            let coinUids = Array(Set(items.compactMap { $0.element.priceCoinUid }))
            self._handleUpdated(priceItemMap: self.coinPriceService.itemMap(coinUids: coinUids), items: items)
        }
    }

    func didUpdate(itemsMap: [String: WalletCoinPriceService.Item]) {
        queue.async {
            guard case .loaded(let items) = self.internalState else {
                return
            }

            self._handleUpdated(priceItemMap: itemsMap, items: items)
        }
    }

}

extension WalletService {

    var activeAccountObservable: Observable<Account?> {
        activeAccountRelay.asObservable()
    }

    var itemUpdatedObservable: Observable<Item> {
        itemUpdatedRelay.asObservable()
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

    var cexAccount: Bool {
        accountManager.activeAccount?.cexAccount ?? false
    }

    var withdrawalAllowed: Bool {
        accountManager.activeAccount?.type.withdrawalAllowed ?? false
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
            guard case .loaded(let items) = internalState else {
                return nil
            }

            return _item(element: element, items: items)
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
        elementService?.refresh()

        queue.async {
            self.coinPriceService.refresh()
        }
    }

    func disable(element: WalletModule.Element) {
        elementService?.disable(element: element)
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

    enum State: CustomStringConvertible {
        case noAccount
        case loading
        case loaded(items: [Item])
        case failed(reason: WalletModule.FailureReason)

        var description: String {
            switch self {
            case .noAccount: return "noAccount"
            case .loading: return "loading"
            case .loaded(let items): return "loaded: \(items.count) items"
            case .failed: return "failed"
            }
        }
    }

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

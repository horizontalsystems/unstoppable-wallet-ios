import Combine
import Foundation
import HsExtensions
import HsToolKit
import RxRelay
import RxSwift

protocol IWalletElementService: AnyObject {
    var delegate: IWalletElementServiceDelegate? { get set }
    var state: WalletModule.ElementState { get }
    func isMainNet(wallet: Wallet) -> Bool?
    func balanceData(wallet: Wallet) -> BalanceData?
    func state(wallet: Wallet) -> AdapterState?
    func refresh()
    func disable(wallet: Wallet)
}

protocol IWalletElementServiceDelegate: AnyObject {
    func didUpdate(elementState: WalletModule.ElementState, elementService: IWalletElementService)
    func didUpdateElements(elementService: IWalletElementService)
    func didUpdate(isMainNet: Bool, wallet: Wallet)
    func didUpdate(balanceData: BalanceData, wallet: Wallet)
    func didUpdate(state: AdapterState, wallet: Wallet)
}

class WalletService {
    private let keySortType = "wallet-sort-type"

    private let elementServiceFactory: WalletElementServiceFactory
    private let coinPriceService: WalletCoinPriceService
    private let accountManager: AccountManager
    private let cacheManager: EnabledWalletCacheManager
    private let accountRestoreWarningManager: AccountRestoreWarningManager
    private let reachabilityManager: IReachabilityManager
    private let appSettingManager: AppSettingManager
    private let balanceHiddenManager: BalanceHiddenManager
    private let buttonHiddenManager: WalletButtonHiddenManager
    private let balanceConversionManager: BalanceConversionManager
    private let cloudAccountBackupManager: CloudBackupManager
    private let rateAppManager: RateAppManager
    private let feeCoinProvider: FeeCoinProvider
    private let userDefaultsStorage: UserDefaultsStorage
    private let sorter = WalletSorter()
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    private var internalState: State = .loading {
        didSet {
            switch internalState {
            case let .loaded(items):
                state = .loaded(items: items)
            default:
                state = internalState
            }
        }
    }

    private var elementService: IWalletElementService?

    @PostPublished private(set) var state: State = .loading
    @PostPublished private(set) var totalItem: TotalItem?

    private let activeAccountRelay = PublishRelay<Account?>()
    private let accountsLostRelay = PublishRelay<Void>()
    private let itemUpdatedRelay = PublishRelay<Item>()

    private let sortTypeRelay = PublishRelay<WalletModule.SortType>()
    var sortType: WalletModule.SortType {
        didSet {
            sortTypeRelay.accept(sortType)
            handleUpdateSortType()
            userDefaultsStorage.set(value: sortType.rawValue, for: keySortType)
        }
    }

    private let queue = DispatchQueue(label: "\(AppConfig.label).wallet-service", qos: .userInitiated)

    init(elementServiceFactory: WalletElementServiceFactory, coinPriceService: WalletCoinPriceService, accountManager: AccountManager,
         cacheManager: EnabledWalletCacheManager, accountRestoreWarningManager: AccountRestoreWarningManager, reachabilityManager: IReachabilityManager,
         appSettingManager: AppSettingManager, balanceHiddenManager: BalanceHiddenManager,
         buttonHiddenManager: WalletButtonHiddenManager, balanceConversionManager: BalanceConversionManager,
         cloudAccountBackupManager: CloudBackupManager, rateAppManager: RateAppManager, appManager: IAppManager, feeCoinProvider: FeeCoinProvider,
         userDefaultsStorage: UserDefaultsStorage)
    {
        self.elementServiceFactory = elementServiceFactory
        self.coinPriceService = coinPriceService
        self.accountManager = accountManager
        self.cacheManager = cacheManager
        self.accountRestoreWarningManager = accountRestoreWarningManager
        self.reachabilityManager = reachabilityManager
        self.appSettingManager = appSettingManager
        self.balanceHiddenManager = balanceHiddenManager
        self.buttonHiddenManager = buttonHiddenManager
        self.balanceConversionManager = balanceConversionManager
        self.cloudAccountBackupManager = cloudAccountBackupManager
        self.rateAppManager = rateAppManager
        self.feeCoinProvider = feeCoinProvider
        self.userDefaultsStorage = userDefaultsStorage

        if let rawValue: String = userDefaultsStorage.value(for: keySortType), let sortType = WalletModule.SortType(rawValue: rawValue) {
            self.sortType = sortType
        } else if let rawValue: Int = userDefaultsStorage.value(for: "balance_sort_key"), rawValue < WalletModule.SortType.allCases.count {
            // TODO: temp solution for restoring from version 0.22
            sortType = WalletModule.SortType.allCases[rawValue]
        } else {
            sortType = .balance
        }

        accountManager.activeAccountPublisher
            .sink { [weak self] in self?.handleUpdated(activeAccount: $0) }
            .store(in: &cancellables)

        accountManager.accountUpdatedPublisher
            .sink { [weak self] in self?.handleUpdated(account: $0) }
            .store(in: &cancellables)

        accountManager.accountDeletedPublisher
            .sink { [weak self] in self?.handleDeleted(account: $0) }
            .store(in: &cancellables)

        accountManager.accountsLostPublisher
            .sink { [weak self] isAccountsLost in
                if isAccountsLost {
                    self?.accountsLostRelay.accept(())
                }
            }
            .store(in: &cancellables)

        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in
            self?.coinPriceService.refresh()
        }

        balanceConversionManager.$conversionToken.sink { [weak self] _ in self?.syncTotalItem() }.store(in: &cancellables)

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
        case let .loaded(wallets):
            let cacheContainer = activeAccount.map { cacheManager.cacheContainer(accountId: $0.id) }
            let priceItemMap = coinPriceService.itemMap(coinUids: wallets.compactMap(\.priceCoinUid))

            let items: [Item] = wallets.map { wallet in
                let item = Item(
                    wallet: wallet,
                    isMainNet: elementService.isMainNet(wallet: wallet) ?? fallbackIsMainNet,
                    balanceData: elementService.balanceData(wallet: wallet) ?? _cachedBalanceData(wallet: wallet, cacheContainer: cacheContainer) ?? fallbackBalanceData,
                    state: elementService.state(wallet: wallet) ?? fallbackAdapterState
                )

                if let priceCoinUid = wallet.priceCoinUid {
                    item.priceItem = priceItemMap[priceCoinUid]
                }

                return item
            }

            internalState = .loaded(items: sorter.sort(items: items, sortType: sortType))
            _syncTotalItem()

            coinPriceService.set(
                coinUids: Set(wallets.compactMap(\.priceCoinUid)),
                feeCoinUids: Set(wallets.compactMap { feeCoinProvider.feeToken(token: $0.token) }.map(\.coin.uid)),
                conversionCoinUids: Set(balanceConversionManager.conversionTokens.map(\.coin.uid))
            )
        case let .failed(reason):
            internalState = .failed(reason: reason)
        }
    }

    private func _cachedBalanceData(wallet: Wallet, cacheContainer: EnabledWalletCacheManager.CacheContainer?) -> BalanceData? {
        cacheContainer?.balanceData(wallet: wallet)
    }

    private func _sorted(items: [Item]) -> [Item] {
        sorter.sort(items: items, sortType: sortType)
    }

    private func _item(wallet: Wallet, items: [Item]) -> Item? {
        items.first { $0.wallet == wallet }
    }

    private func handleUpdated(activeAccount: Account?) {
        queue.async {
            self.sync(activeAccount: activeAccount)
        }

        activeAccountRelay.accept(activeAccount)
    }

    private func handleUpdateSortType() {
        queue.async {
            guard case let .loaded(items) = self.internalState else {
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
        guard case let .loaded(items) = state else {
            return
        }

        var total: Decimal = 0
        var expired = false

        for item in items {
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

        var convertedValue: AppValue?
        var convertedValueExpired = false

        if let conversionToken = balanceConversionManager.conversionToken, let priceItem = coinPriceService.item(coinUid: conversionToken.coin.uid) {
            convertedValue = AppValue(token: conversionToken, value: total / priceItem.price.value)
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
            guard case let .loaded(items) = self.internalState else {
                return
            }

            var balanceDataMap = [Wallet: BalanceData]()

            for item in items {
                let balanceData = elementService.balanceData(wallet: item.wallet) ?? self.fallbackBalanceData

                item.isMainNet = elementService.isMainNet(wallet: item.wallet) ?? self.fallbackIsMainNet
                item.balanceData = balanceData
                item.state = elementService.state(wallet: item.wallet) ?? self.fallbackAdapterState

                balanceDataMap[item.wallet] = balanceData
            }

            self.internalState = .loaded(items: self._sorted(items: items))
            self._syncTotalItem()

            if !balanceDataMap.isEmpty {
                self.cacheManager.set(balanceDataMap: balanceDataMap)
            }
        }
    }

    func didUpdate(isMainNet: Bool, wallet: Wallet) {
        queue.async {
            guard case let .loaded(items) = self.internalState, let item = self._item(wallet: wallet, items: items) else {
                return
            }

            item.isMainNet = isMainNet

            self.itemUpdatedRelay.accept(item)
        }
    }

    func didUpdate(balanceData: BalanceData, wallet: Wallet) {
        queue.async {
            guard case let .loaded(items) = self.internalState, let item = self._item(wallet: wallet, items: items) else {
                return
            }

            item.balanceData = balanceData

            if self.sortType == .balance, items.allSatisfy(\.state.isSynced) {
                self.internalState = .loaded(items: self._sorted(items: items))
            } else {
                self.itemUpdatedRelay.accept(item)
            }

            self._syncTotalItem()

            self.cacheManager.set(balanceData: balanceData, wallet: wallet)
        }
    }

    func didUpdate(state: AdapterState, wallet: Wallet) {
        queue.async {
            guard case let .loaded(items) = self.internalState, let item = self._item(wallet: wallet, items: items) else {
                return
            }

            let oldState = item.state
            item.state = state

            if self.sortType == .balance, items.allSatisfy(\.state.isSynced) {
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
            if let priceCoinUid = item.wallet.priceCoinUid {
                item.priceItem = priceItemMap[priceCoinUid]
            }
        }

        internalState = .loaded(items: _sorted(items: items))
        _syncTotalItem()
    }

    func didUpdate(itemsMap: [String: WalletCoinPriceService.Item]?) {
        queue.async {
            guard case let .loaded(items) = self.internalState else {
                return
            }

            let _itemsMap: [String: WalletCoinPriceService.Item]
            if let itemsMap {
                _itemsMap = itemsMap
            } else {
                let coinUids = Array(Set(items.compactMap(\.wallet.priceCoinUid)))
                _itemsMap = self.coinPriceService.itemMap(coinUids: coinUids)
            }

            self._handleUpdated(priceItemMap: _itemsMap, items: items)
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

    var accountsLostObservable: Observable<Void> {
        accountsLostRelay.asObservable()
    }

    var sortTypeObservable: Observable<WalletModule.SortType> {
        sortTypeRelay.asObservable()
    }

    var balancePrimaryValueObservable: Observable<BalancePrimaryValue> {
        appSettingManager.balancePrimaryValueObservable
    }

    var balancePrimaryValue: BalancePrimaryValue {
        appSettingManager.balancePrimaryValue
    }

    var balanceHiddenObservable: Observable<Bool> {
        balanceHiddenManager.balanceHiddenObservable
    }

    var buttonHiddenObservable: Observable<Bool> {
        buttonHiddenManager.buttonHiddenObservable
    }

    var activeAccount: Account? {
        accountManager.activeAccount
    }

    var watchAccount: Bool {
        accountManager.activeAccount?.watchAccount ?? false
    }

    var withdrawalAllowed: Bool {
        accountManager.activeAccount != nil
    }

    var lastCreatedAccount: Account? {
        accountManager.popLastCreatedAccount()
    }

    var balanceHidden: Bool {
        balanceHiddenManager.balanceHidden
    }

    var buttonHidden: Bool {
        buttonHiddenManager.buttonHidden
    }

    var isReachable: Bool {
        reachabilityManager.isReachable
    }

    func item(wallet: Wallet) -> Item? {
        queue.sync {
            guard case let .loaded(items) = internalState else {
                return nil
            }

            return _item(wallet: wallet, items: items)
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

    func disable(wallet: Wallet) {
        elementService?.disable(wallet: wallet)
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
            case let .loaded(items): return "loaded: \(items.count) items"
            case .failed: return "failed"
            }
        }
    }

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
        let convertedValue: AppValue?
        let convertedValueExpired: Bool
    }
}

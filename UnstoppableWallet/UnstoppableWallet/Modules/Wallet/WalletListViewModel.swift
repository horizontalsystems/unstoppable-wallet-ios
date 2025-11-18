import Combine
import Foundation
import MarketKit
import RxSwift

class WalletListViewModel: ObservableObject {
    private let keySortType = "wallet-sort-type"

    private let walletServiceFactory = WalletServiceFactory()
    let coinPriceService = WalletCoinPriceService()
    private let sorter = WalletSorter()
    let balanceHiddenManager = Core.shared.balanceHiddenManager
    let accountManager = Core.shared.accountManager
    private let reachabilityManager = Core.shared.reachabilityManager
    private let userDefaultsStorage = Core.shared.userDefaultsStorage
    private let cacheManager = Core.shared.enabledWalletCacheManager
    private let feeCoinProvider = Core.shared.feeCoinProvider
    private let appSettingManager = Core.shared.appSettingManager
    private let amountRoundingManager = Core.shared.amountRoundingManager

    let disposeBag = DisposeBag()
    var cancellables = Set<AnyCancellable>()

    @Published private(set) var account: Account?
    @Published private(set) var balancePrimaryValue: BalancePrimaryValue
    @Published private(set) var balanceHidden: Bool
    @Published private(set) var amountRounding: Bool

    @Published var sortType: WalletSorter.SortType {
        didSet {
            handleUpdateSortType()
            userDefaultsStorage.set(value: sortType.rawValue, for: keySortType)
        }
    }

    @Published private(set) var items: [Item] = []
    @Published private(set) var isReachable: Bool = true

    var walletService: WalletService?

    var __items: [Item] = []
    let queue = DispatchQueue(label: "\(AppConfig.label).wallet-list-view-model", qos: .userInitiated)

    init() {
        if let rawValue: String = userDefaultsStorage.value(for: keySortType), let sortType = WalletSorter.SortType(rawValue: rawValue) {
            self.sortType = sortType
        } else {
            sortType = .balance
        }

        account = accountManager.activeAccount
        balancePrimaryValue = appSettingManager.balancePrimaryValue
        balanceHidden = balanceHiddenManager.balanceHidden
        amountRounding = amountRoundingManager.useAmountRounding
        isReachable = reachabilityManager.isReachable

        coinPriceService.delegate = self

        accountManager.activeAccountPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handleUpdated(activeAccount: $0) }
            .store(in: &cancellables)

        accountManager.accountUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handleUpdated(account: $0) }
            .store(in: &cancellables)

        appSettingManager.balancePrimaryValueObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.balancePrimaryValue = $0
            })
            .disposed(by: disposeBag)

        balanceHiddenManager.balanceHiddenObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.balanceHidden = $0
            })
            .disposed(by: disposeBag)

        amountRoundingManager.amountRoundingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.amountRounding = $0
            }
            .store(in: &cancellables)

        reachabilityManager.$isReachable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isReachable = $0 }
            .store(in: &cancellables)

        _syncWalletService()
    }

    private func handleUpdated(activeAccount: Account?) {
        account = activeAccount

        queue.async {
            self._syncWalletService()
        }
    }

    private func handleUpdated(account: Account) {
        if account.id == self.account?.id {
            self.account = account
        }
    }

    private func handleUpdateSortType() {
        queue.async {
            self._sortItems()
            self._reportItems()
        }
    }

    private func _sortItems() {
        __items = sorter.sort(items: __items, sortType: sortType)
    }

    private func _reportItems() {
        DispatchQueue.main.async { [__items] in
            self.items = __items
        }
    }

    private func _itemIndex(wallet: Wallet) -> Int? {
        __items.firstIndex { $0.wallet == wallet }
    }

    private func _syncWalletService() {
        walletService?.delegate = nil

        if let account {
            let walletService = walletServiceFactory.walletService(account: account)
            walletService.delegate = self
            self.walletService = walletService

            _sync(wallets: walletService.wallets, walletService: walletService)
        } else {
            walletService = nil
            __items = []
            _reportItems()
        }
    }

    private func _sync(wallets: [Wallet], walletService: WalletService) {
        let cacheContainer = account.map { cacheManager.cacheContainer(accountId: $0.id) }
        let priceItemMap = coinPriceService.itemMap(coinUids: wallets.compactMap(\.priceCoinUid))

        __items = wallets.map { wallet in
            var item = Item(
                wallet: wallet,
                isMainNet: walletService.isMainNet(wallet: wallet) ?? fallbackIsMainNet,
                balanceData: walletService.balanceData(wallet: wallet) ?? _cachedBalanceData(wallet: wallet, cacheContainer: cacheContainer) ?? fallbackBalanceData,
                state: walletService.state(wallet: wallet) ?? fallbackAdapterState
            )

            if let priceCoinUid = wallet.priceCoinUid {
                item.priceItem = priceItemMap[priceCoinUid]
            }

            return item
        }

        _sortItems()
        _reportItems()

        _syncTotalItem()

        coinPriceService.set(
            coinUids: Set(wallets.compactMap(\.priceCoinUid)),
            feeCoinUids: Set(wallets.compactMap { feeCoinProvider.feeToken(token: $0.token) }.map(\.coin.uid)),
            conversionCoinUids: conversionCoinUids
        )
    }

    private func _cachedBalanceData(wallet: Wallet, cacheContainer: EnabledWalletCacheManager.CacheContainer?) -> BalanceData? {
        cacheContainer?.balanceData(wallet: wallet)
    }

    private var fallbackIsMainNet: Bool {
        true
    }

    private var fallbackBalanceData: BalanceData {
        BalanceData(balance: 0)
    }

    private var fallbackAdapterState: AdapterState {
        .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
    }

    var conversionCoinUids: Set<String> {
        []
    }

    func _syncTotalItem() {}
}

extension WalletListViewModel: IWalletServiceDelegate {
    func didUpdateWallets(walletService: WalletService) {
        queue.async {
            var balanceDataMap = [Wallet: BalanceData]()

            for index in self.__items.indices {
                let wallet = self.__items[index].wallet

                let balanceData = walletService.balanceData(wallet: wallet) ?? self.fallbackBalanceData

                self.__items[index].isMainNet = walletService.isMainNet(wallet: wallet) ?? self.fallbackIsMainNet
                self.__items[index].balanceData = balanceData
                self.__items[index].state = walletService.state(wallet: wallet) ?? self.fallbackAdapterState

                balanceDataMap[wallet] = balanceData
            }

            self._sortItems()
            self._reportItems()

            self._syncTotalItem()

            if !balanceDataMap.isEmpty {
                self.cacheManager.set(balanceDataMap: balanceDataMap)
            }
        }
    }

    func didUpdate(wallets: [Wallet], walletService: WalletService) {
        queue.async {
            self._sync(wallets: wallets, walletService: walletService)
        }
    }

    func didUpdate(isMainNet: Bool, wallet: Wallet) {
        queue.async {
            guard let index = self._itemIndex(wallet: wallet) else {
                return
            }

            self.__items[index].isMainNet = isMainNet
            self._reportItems()
        }
    }

    func didUpdate(balanceData: BalanceData, wallet: Wallet) {
        queue.async {
            guard let index = self._itemIndex(wallet: wallet) else {
                return
            }

            self.__items[index].balanceData = balanceData

            if self.sortType == .balance, self.__items.allSatisfy(\.state.isSynced) {
                self._sortItems()
            }

            self._reportItems()
            self._syncTotalItem()

            self.cacheManager.set(balanceData: balanceData, wallet: wallet)
        }
    }

    func didUpdate(state: AdapterState, wallet: Wallet) {
        queue.async {
            guard let index = self._itemIndex(wallet: wallet) else {
                return
            }

            let oldState = self.__items[index].state
            self.__items[index].state = state

            if self.sortType == .balance, self.__items.allSatisfy(\.state.isSynced) {
                self._sortItems()
            }

            self._reportItems()

            if oldState.isSynced != state.isSynced {
                self._syncTotalItem()
            }
        }
    }
}

extension WalletListViewModel: IWalletCoinPriceServiceDelegate {
    private func _handleUpdated(priceItemMap: [String: WalletCoinPriceService.Item]) {
        for index in __items.indices {
            if let priceCoinUid = __items[index].wallet.priceCoinUid {
                __items[index].priceItem = priceItemMap[priceCoinUid]
            }
        }

        _sortItems()
        _reportItems()
        _syncTotalItem()
    }

    func didUpdate(itemsMap: [String: WalletCoinPriceService.Item]?) {
        queue.async {
            let _itemsMap: [String: WalletCoinPriceService.Item]
            if let itemsMap {
                _itemsMap = itemsMap
            } else {
                let coinUids = Array(Set(self.__items.compactMap(\.wallet.priceCoinUid)))
                _itemsMap = self.coinPriceService.itemMap(coinUids: coinUids)
            }

            self._handleUpdated(priceItemMap: _itemsMap)
        }
    }
}

extension WalletListViewModel {
    struct Item: Hashable, ISortableWalletItem {
        let wallet: Wallet
        var isMainNet: Bool
        var balanceData: BalanceData
        var state: AdapterState
        var priceItem: WalletCoinPriceService.Item?

        var balance: Decimal {
            balanceData.available
        }

        var name: String {
            wallet.coin.name
        }

        var diff: Decimal? {
            priceItem?.diff
        }
    }
}

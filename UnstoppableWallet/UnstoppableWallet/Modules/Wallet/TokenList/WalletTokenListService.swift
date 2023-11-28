import Combine
import Foundation
import HsExtensions
import HsToolKit
import RxRelay
import RxSwift

class WalletTokenListService: IWalletTokenListService {
    private let elementService: IWalletElementService
    private let coinPriceService: WalletCoinPriceService
    private let cacheManager: EnabledWalletCacheManager
    private let reachabilityManager: IReachabilityManager
    private let balancePrimaryValueManager: BalancePrimaryValueManager
    private let balanceHiddenManager: BalanceHiddenManager
    private let feeCoinProvider: FeeCoinProvider
    private let account: Account

    private let sorter = WalletSorter()
    private let disposeBag = DisposeBag()

    var elementFilter: ((WalletModule.Element) -> Bool)?

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

    var state: State = .loading {
        didSet {
            stateUpdatedSubject.send(state)
        }
    }

    let stateUpdatedSubject = PassthroughSubject<State, Never>()

    private let itemUpdatedRelay = PublishRelay<Item>()

    private let queue = DispatchQueue(label: "\(AppConfig.label).wallet-token-list-service", qos: .userInitiated)

    init(elementService: IWalletElementService, coinPriceService: WalletCoinPriceService,
         cacheManager: EnabledWalletCacheManager, reachabilityManager: IReachabilityManager,
         balancePrimaryValueManager: BalancePrimaryValueManager, balanceHiddenManager: BalanceHiddenManager,
         appManager: IAppManager, feeCoinProvider: FeeCoinProvider, account: Account)
    {
        self.elementService = elementService
        self.coinPriceService = coinPriceService
        self.cacheManager = cacheManager
        self.reachabilityManager = reachabilityManager
        self.balancePrimaryValueManager = balancePrimaryValueManager
        self.balanceHiddenManager = balanceHiddenManager
        self.feeCoinProvider = feeCoinProvider
        self.account = account

        self.elementService.delegate = self

        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in
            self?.coinPriceService.refresh()
        }

        queue.async {
            self.sync(elementState: elementService.state, elementService: elementService)
        }
    }

    private func sync(elementState: WalletModule.ElementState, elementService: IWalletElementService) {
        switch elementState {
        case .loading:
            internalState = .loading
        case let .loaded(elements):
            let cacheContainer = cacheManager.cacheContainer(accountId: account.id)
            let priceItemMap = coinPriceService.itemMap(coinUids: elements.compactMap(\.priceCoinUid))

            let items: [Item] = elements.filter { elementFilter?($0) ?? true }
                .map { element in
                    let item = Item(
                        element: element,
                        isMainNet: elementService.isMainNet(element: element) ?? fallbackIsMainNet,
                        balanceData: elementService.balanceData(element: element) ?? _cachedBalanceData(element: element, cacheContainer: cacheContainer) ?? fallbackBalanceData,
                        state: elementService.state(element: element) ?? fallbackAdapterState
                    )

                    if let priceCoinUid = element.priceCoinUid {
                        item.priceItem = priceItemMap[priceCoinUid]
                    }

                    return item
                }

            internalState = .loaded(items: sorter.sort(items: items, sortType: .balance))

            let coinUids = Set(elements.compactMap(\.priceCoinUid))
            let feeCoinUids = Set(elements.compactMap(\.wallet)
                .compactMap {
                    feeCoinProvider.feeToken(token: $0.token)
                }
                .map(\.coin.uid))

            coinPriceService.set(coinUids: coinUids.union(feeCoinUids))
        case let .failed(reason):
            internalState = .failed(reason: reason)
        }
    }

    private func _cachedBalanceData(element: WalletModule.Element, cacheContainer: EnabledWalletCacheManager.CacheContainer?) -> BalanceData? {
        switch element {
        case let .wallet(wallet): return cacheContainer?.balanceData(wallet: wallet)
        default: return nil
        }
    }

    private func _sorted(items: [Item]) -> [Item] {
        sorter.sort(items: items, sortType: .balance)
    }

    private func _item(element: WalletModule.Element, items: [Item]) -> Item? {
        items.first {
            $0.element == element
        }
    }

    var stateUpdatedPublisher: AnyPublisher<WalletTokenListService.State, Never> {
        stateUpdatedSubject.eraseToAnyPublisher()
    }

    var balanceHiddenObservable: Observable<Bool> {
        balanceHiddenManager.balanceHiddenObservable
    }

    var balanceHidden: Bool {
        balanceHiddenManager.balanceHidden
    }

    var balancePrimaryValueObservable: Observable<BalancePrimaryValue> {
        balancePrimaryValueManager.balancePrimaryValueObservable
    }

    var balancePrimaryValue: BalancePrimaryValue {
        balancePrimaryValueManager.balancePrimaryValue
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

extension WalletTokenListService: IWalletElementServiceDelegate {
    func didUpdate(elementState: WalletModule.ElementState, elementService: IWalletElementService) {
        queue.async {
            self.sync(elementState: elementState, elementService: elementService)
        }
    }

    func didUpdateElements(elementService: IWalletElementService) {
        queue.async {
            guard case let .loaded(items) = self.internalState else {
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

            if !balanceDataMap.isEmpty {
                self.cacheManager.set(balanceDataMap: balanceDataMap)
            }
        }
    }

    func didUpdate(isMainNet: Bool, element: WalletModule.Element) {
        queue.async {
            guard case let .loaded(items) = self.internalState, let item = self._item(element: element, items: items) else {
                return
            }

            item.isMainNet = isMainNet

            self.itemUpdatedRelay.accept(item)
        }
    }

    func didUpdate(balanceData: BalanceData, element: WalletModule.Element) {
        queue.async {
            guard case let .loaded(items) = self.internalState, let item = self._item(element: element, items: items) else {
                return
            }

            item.balanceData = balanceData

            if items.allSatisfy(\.state.isSynced) {
                self.internalState = .loaded(items: self._sorted(items: items))
            } else {
                self.itemUpdatedRelay.accept(item)
            }

            if let wallet = element.wallet {
                self.cacheManager.set(balanceData: balanceData, wallet: wallet)
            }
        }
    }

    func didUpdate(state: AdapterState, element: WalletModule.Element) {
        queue.async {
            guard case let .loaded(items) = self.internalState, let item = self._item(element: element, items: items) else {
                return
            }

            item.state = state

            if items.allSatisfy(\.state.isSynced) {
                self.internalState = .loaded(items: self._sorted(items: items))
            } else {
                self.itemUpdatedRelay.accept(item)
            }
        }
    }
}

extension WalletTokenListService: IWalletCoinPriceServiceDelegate {
    private func _handleUpdated(priceItemMap: [String: WalletCoinPriceService.Item], items: [Item]) {
        for item in items {
            if let priceCoinUid = item.element.priceCoinUid {
                item.priceItem = priceItemMap[priceCoinUid]
            }
        }

        internalState = .loaded(items: _sorted(items: items))
    }

    func didUpdateBaseCurrency() {
        queue.async {
            guard case let .loaded(items) = self.internalState else {
                return
            }

            let coinUids = Array(Set(items.compactMap(\.element.priceCoinUid)))
            self._handleUpdated(priceItemMap: self.coinPriceService.itemMap(coinUids: coinUids), items: items)
        }
    }

    func didUpdate(itemsMap: [String: WalletCoinPriceService.Item]) {
        queue.async {
            guard case let .loaded(items) = self.internalState else {
                return
            }

            self._handleUpdated(priceItemMap: itemsMap, items: items)
        }
    }
}

extension WalletTokenListService {
    var itemUpdatedObservable: Observable<Item> {
        itemUpdatedRelay.asObservable()
    }

    var isReachable: Bool {
        reachabilityManager.isReachable
    }

    func item(element: WalletModule.Element) -> Item? {
        queue.sync {
            guard case let .loaded(items) = internalState else {
                return nil
            }

            return _item(element: element, items: items)
        }
    }
}

extension WalletTokenListService {
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
        let element: WalletModule.Element
        var isMainNet: Bool
        var balanceData: BalanceData
        var state: AdapterState
        var priceItem: WalletCoinPriceService.Item?

        init(element: WalletModule.Element, isMainNet: Bool, balanceData: BalanceData, state: AdapterState) {
            self.element = element
            self.isMainNet = isMainNet
            self.balanceData = balanceData
            self.state = state
        }
    }
}

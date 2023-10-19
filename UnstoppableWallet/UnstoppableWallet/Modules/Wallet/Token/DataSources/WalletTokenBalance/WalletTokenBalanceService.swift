import Combine
import Foundation
import RxSwift
import CurrencyKit
import HsExtensions

class WalletTokenBalanceService {
    private let disposeBag = DisposeBag()

    private let coinPriceService: WalletCoinPriceService
    private let elementService: IWalletElementService
    private let cloudAccountBackupManager: CloudBackupManager
    private let balanceHiddenManager: BalanceHiddenManager
    private let reachabilityManager: IReachabilityManager

    private let account: Account
    let element: WalletModule.Element

    @PostPublished private(set) var item: BalanceItem?
    private let itemUpdatedSubject = PassthroughSubject<Void, Never>()
    private let balanceHiddenSubject = PassthroughSubject<Bool, Never>()

    private let queue = DispatchQueue(label: "\(AppConfig.label).wallet-token-balance-service", qos: .userInitiated)

    init(coinPriceService: WalletCoinPriceService, elementService: IWalletElementService,
         appManager: IAppManager, cloudAccountBackupManager: CloudBackupManager,
         balanceHiddenManager: BalanceHiddenManager, reachabilityManager: IReachabilityManager,
         account: Account, element: WalletModule.Element) {
        self.coinPriceService = coinPriceService
        self.elementService = elementService
        self.cloudAccountBackupManager = cloudAccountBackupManager
        self.balanceHiddenManager = balanceHiddenManager
        self.reachabilityManager = reachabilityManager

        self.account = account
        self.element = element

        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in
            self?.coinPriceService.refresh()
        }

        subscribe(disposeBag, balanceHiddenManager.balanceHiddenObservable) { [weak self] in
            self?.balanceHiddenSubject.send($0)
        }

        elementService.delegate = self
        coinPriceService.delegate = self
        coinPriceService.set(coinUids: Set([element.priceCoinUid].compactMap { $0 }))
        sync()
    }

    private func sync() {
        queue.async {
            self._sync()
        }
    }

    private func _sync() {
        let priceItemMap = coinPriceService.itemMap(coinUids: [element.priceCoinUid].compactMap { $0 })

        let item = BalanceItem(
                element: element,
                isMainNet: elementService.isMainNet(element: element) ?? fallbackIsMainNet,
                watchAccount: account.watchAccount,
                balanceData: elementService.balanceData(element: element) ?? fallbackBalanceData,
                state: elementService.state(element: element) ?? fallbackAdapterState
        )

        if let priceCoinUid = element.priceCoinUid {
            item.priceItem = priceItemMap[priceCoinUid]
        }

        self.item = item
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

    var isReachable: Bool {
        reachabilityManager.isReachable
    }

}

extension WalletTokenBalanceService {

    var itemUpdatedPublisher: AnyPublisher<Void, Never> {
        itemUpdatedSubject.eraseToAnyPublisher()
    }

    var balanceHidden: Bool {
        balanceHiddenManager.balanceHidden
    }

    var balanceHiddenPublisher: AnyPublisher<Bool, Never> {
        balanceHiddenSubject.eraseToAnyPublisher()
    }

    func isCloudBackedUp() -> Bool {
        cloudAccountBackupManager.backedUp(uniqueId: account.type.uniqueId())
    }

    func toggleBalanceHidden() {
        balanceHiddenManager.toggleBalanceHidden()
    }

}

extension WalletTokenBalanceService {

    class BalanceItem {
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

}

extension WalletTokenBalanceService: IWalletElementServiceDelegate {

    func didUpdate(elementState: WalletModule.ElementState, elementService: IWalletElementService) {
        queue.async { [weak self] in
            self?._sync()
        }
    }

    func didUpdateElements(elementService: IWalletElementService) {}

    func didUpdate(isMainNet: Bool, element: WalletModule.Element) {
        guard element == self.element else {
            return
        }
        queue.async { [weak self] in
            self?.item?.isMainNet = isMainNet
            self?.itemUpdatedSubject.send()
        }
    }

    func didUpdate(balanceData: BalanceData, element: WalletModule.Element) {
        guard element == self.element else {
            return
        }
        queue.async { [weak self] in
            self?.item?.balanceData = balanceData
            self?.itemUpdatedSubject.send()
        }
    }

    func didUpdate(state: AdapterState, element: WalletModule.Element) {
        guard element == self.element else {
            return
        }
        queue.async { [weak self] in
            self?.item?.state = state
            self?.itemUpdatedSubject.send()
        }
    }

}

extension WalletTokenBalanceService: IWalletCoinPriceServiceDelegate {

    private func _handleUpdated(priceItemMap: [String: WalletCoinPriceService.Item], items: [BalanceItem]) {
        queue.async { [weak self] in
            if let priceCoinUid = self?.element.priceCoinUid {
                self?.item?.priceItem = priceItemMap[priceCoinUid]
                self?.itemUpdatedSubject.send()
            }
        }
    }

    func didUpdateBaseCurrency() {}
    func didUpdate(itemsMap: [String: WalletCoinPriceService.Item]) {}

}

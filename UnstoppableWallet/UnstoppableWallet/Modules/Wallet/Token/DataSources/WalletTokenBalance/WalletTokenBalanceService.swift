import Foundation
import RxSwift
import CurrencyKit
import HsExtensions

class WalletTokenBalanceService {
    private let disposeBag = DisposeBag()

    private let coinPriceService: WalletCoinPriceService
    private let account: Account
    private let element: WalletModule.Element
    private let elementService: IWalletElementService

    @PostPublished private(set) var item: Item?

    private let queue = DispatchQueue(label: "\(AppConfig.label).wallet-token-balance-service", qos: .userInitiated)

    init(coinPriceService: WalletCoinPriceService, elementService: IWalletElementService, appManager: IAppManager, account: Account, element: WalletModule.Element) {
        self.coinPriceService = coinPriceService
        self.elementService = elementService
        self.account = account
        self.element = element

        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in
            self?.coinPriceService.refresh()
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

        let item = Item(
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
        BalanceData(balance: 0)
    }

    private var fallbackAdapterState: AdapterState {
        .syncing(progress: nil, lastBlockDate: nil)
    }

}

extension WalletTokenBalanceService {

    var wallet: Wallet {
        element.wallet!
    }

}

extension WalletTokenBalanceService {

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

}

extension WalletTokenBalanceService: IWalletElementServiceDelegate {

    func didUpdate(elementState: WalletModule.ElementState, elementService: IWalletElementService) {
        queue.async {
            self._sync()
        }
    }

    func didUpdateElements(elementService: IWalletElementService) {
    }

    func didUpdate(isMainNet: Bool, element: WalletModule.Element) {
        queue.async {
            self.item?.isMainNet = isMainNet
        }
    }

    func didUpdate(balanceData: BalanceData, element: WalletModule.Element) {
        queue.async {
            self.item?.balanceData = balanceData
        }
    }

    func didUpdate(state: AdapterState, element: WalletModule.Element) {
        queue.async {
            self.item?.state = state
        }
    }

}

extension WalletTokenBalanceService: IWalletCoinPriceServiceDelegate {

    private func _handleUpdated(priceItemMap: [String: WalletCoinPriceService.Item], items: [Item]) {
//        for item in items {
//            if let priceCoinUid = item.element.priceCoinUid {
//                item.priceItem = priceItemMap[priceCoinUid]
//            }
//        }
//
//        internalState = .loaded(items: _sorted(items: items))
//        _syncTotalItem()
    }

    func didUpdateBaseCurrency() {
        queue.async {
//            guard case .loaded(let items) = self.internalState else {
//                return
//            }
//
//            let coinUids = Array(Set(items.compactMap { $0.element.priceCoinUid }))
//            self._handleUpdated(priceItemMap: self.coinPriceService.itemMap(coinUids: coinUids), items: items)
        }
    }

    func didUpdate(itemsMap: [String: WalletCoinPriceService.Item]) {
        queue.async {
//            guard case .loaded(let items) = self.internalState else {
//                return
//            }
//
//            self._handleUpdated(priceItemMap: itemsMap, items: items)
        }
    }

}

import Foundation
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit
import EvmKit
import HsToolKit

class WalletService {
    private let commonService: WalletCommonService
    private let adapterService: WalletAdapterService
    private let coinPriceService: WalletCoinPriceService
    private let cacheManager: EnabledWalletCacheManager
    private let walletManager: WalletManager
    private let marketKit: MarketKit.Kit
    private let balanceConversionManager: BalanceConversionManager
    private let feeCoinProvider: FeeCoinProvider
    private let disposeBag = DisposeBag()
    private var walletDisposeBag = DisposeBag()

    private let totalItemRelay = PublishRelay<WalletModule.TotalItem?>()
    private(set) var totalItem: WalletModule.TotalItem? {
        didSet {
            totalItemRelay.accept(totalItem)
        }
    }

    private let balanceItemUpdatedRelay = PublishRelay<IBalanceItem>()

    private let balanceItemsRelay = PublishRelay<[IBalanceItem]>()
    private(set) var balanceItems: [IBalanceItem] = [] {
        didSet {
            balanceItemsRelay.accept(balanceItems)
        }
    }

    private var items: [Item] = [] {
        didSet {
            let hideZeroBalances = commonService.activeAccount?.type.hideZeroBalances ?? false

            if hideZeroBalances {
                balanceItems = items.filter { $0.balanceData.balanceTotal != 0 || $0.wallet.token.type == .native }
            } else {
                balanceItems = items
            }
        }
    }

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.wallet-service", qos: .userInitiated)

    init(commonService: WalletCommonService, adapterService: WalletAdapterService, coinPriceService: WalletCoinPriceService, cacheManager: EnabledWalletCacheManager, walletManager: WalletManager, marketKit: MarketKit.Kit, balanceConversionManager: BalanceConversionManager, appManager: IAppManager, feeCoinProvider: FeeCoinProvider) {
        self.commonService = commonService
        self.adapterService = adapterService
        self.coinPriceService = coinPriceService
        self.cacheManager = cacheManager
        self.walletManager = walletManager
        self.marketKit = marketKit
        self.balanceConversionManager = balanceConversionManager
        self.feeCoinProvider = feeCoinProvider

        subscribe(disposeBag, commonService.sortTypeObservable) { [weak self] _ in
            self?.handleUpdateSortType()
        }
        subscribe(disposeBag, walletManager.activeWalletsUpdatedObservable) { [weak self] in
            self?.sync(wallets: $0)
        }
        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in
            self?.coinPriceService.refresh()
        }
        subscribe(disposeBag, balanceConversionManager.conversionTokenObservable) { [weak self] _ in
            self?.syncTotalItem()
        }

        _sync(wallets: walletManager.activeWallets)
    }

    private func handleUpdateSortType() {
        queue.async {
            self.items = self.commonService.sort(balanceItems: self.items)
        }
    }

    private func sync(wallets: [Wallet]) {
        queue.async { self._sync(wallets: wallets) }
    }

    private func _sync(wallets: [Wallet]) {
        let cacheContainer = commonService.activeAccount.map { cacheManager.cacheContainer(accountId: $0.id) }
        let priceItemMap = coinPriceService.itemMap(tokens: wallets.map { $0.token })
        let watchAccount = commonService.watchAccount

        let items: [Item] = wallets.map { wallet in
            let item = Item(
                    wallet: wallet,
                    isMainNet: adapterService.isMainNet(wallet: wallet) ?? fallbackIsMainNet,
                    watchAccount: watchAccount,
                    balanceData: adapterService.balanceData(wallet: wallet) ?? cacheContainer?.balanceData(wallet: wallet) ?? fallbackBalanceData,
                    state: adapterService.state(wallet: wallet)  ?? fallbackAdapterState
            )

            item.priceItem = priceItemMap[wallet.coin.uid]

            return item
        }

        self.items = commonService.sort(balanceItems: items)
        syncTotalItem()

        let tokens = Set(wallets.map { $0.token })
        let feeCoinTokens = Set(wallets.compactMap { feeCoinProvider.feeToken(token: $0.token) })

        coinPriceService.set(tokens: tokens.union(feeCoinTokens).union(balanceConversionManager.conversionTokens))
    }

    private func items(coinUid: String) -> [Item] {
        items.filter { $0.wallet.coin.uid == coinUid }
    }

    private func syncTotalItem() {
        var total: Decimal = 0
        var expired = false

        balanceItems.forEach { item in
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

        if let conversionToken = balanceConversionManager.conversionToken, let priceItem = coinPriceService.item(token: conversionToken) {
            convertedValue = CoinValue(kind: .token(token: conversionToken), value: total / priceItem.price.value)
            convertedValueExpired = priceItem.expired
        }

        totalItem = WalletModule.TotalItem(
                currencyValue: CurrencyValue(currency: coinPriceService.currency, value: total),
                expired: expired,
                convertedValue: convertedValue,
                convertedValueExpired: expired || convertedValueExpired
        )
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

            self.items = self.commonService.sort(balanceItems: self.items)
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

            self.balanceItemUpdatedRelay.accept(item)
        }
    }

    func didUpdate(balanceData: BalanceData, wallet: Wallet) {
        queue.async {
            guard let item = self._item(wallet: wallet) else {
                return
            }

            item.balanceData = balanceData

            if self.commonService.sortType == .balance, self.items.allSatisfy({ $0.state.isSynced }) {
                self.items = self.commonService.sort(balanceItems: self.items)
            } else {
                self.balanceItemUpdatedRelay.accept(item)
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

            if self.commonService.sortType == .balance, self.items.allSatisfy({ $0.state.isSynced }) {
                self.items = self.commonService.sort(balanceItems: self.items)
            } else {
                self.balanceItemUpdatedRelay.accept(item)
            }

            if oldState.isSynced != state.isSynced {
                self.syncTotalItem()
            }
        }
    }

}

extension WalletService: IWalletCoinPriceServiceDelegate {

    private func handleUpdated(priceItemMap: [String: WalletCoinPriceService.Item]) {
        for item in items {
            item.priceItem = priceItemMap[item.wallet.coin.uid]
        }

        items = commonService.sort(balanceItems: items)
        syncTotalItem()
    }

    func didUpdateBaseCurrency() {
        queue.async {
            self.handleUpdated(priceItemMap: self.coinPriceService.itemMap(tokens: self.items.map { $0.wallet.token }))
        }
    }

    func didUpdate(itemsMap: [String: WalletCoinPriceService.Item]) {
        queue.async {
            self.handleUpdated(priceItemMap: itemsMap)
        }
    }

}

extension WalletService: IWalletService {

    var totalItemObservable: Observable<WalletModule.TotalItem?> {
        totalItemRelay.asObservable()
    }

    var balanceItemUpdatedObservable: Observable<IBalanceItem> {
        balanceItemUpdatedRelay.asObservable()
    }

    var balanceItemsObservable: Observable<[IBalanceItem]> {
        balanceItemsRelay.asObservable()
    }

    func balanceItem(item: WalletModule.Item) -> IBalanceItem? {
        guard let wallet = item.wallet else {
            return nil
        }

        return queue.sync { _item(wallet: wallet) }
    }

    func refresh() {
        adapterService.refresh()
        coinPriceService.refresh()
    }

    func disable(item: WalletModule.Item) {
        guard let wallet = item.wallet else {
            return
        }

        walletManager.delete(wallets: [wallet])
    }

    func toggleConversionCoin() {
        balanceConversionManager.toggleConversionToken()
    }

}

extension WalletService {

    class Item: IBalanceItem {
        let wallet: Wallet
        var isMainNet: Bool
        var watchAccount: Bool
        var balanceData: BalanceData
        var state: AdapterState
        var priceItem: WalletCoinPriceService.Item?

        init(wallet: Wallet, isMainNet: Bool, watchAccount: Bool, balanceData: BalanceData, state: AdapterState) {
            self.wallet = wallet
            self.isMainNet = isMainNet
            self.watchAccount = watchAccount
            self.balanceData = balanceData
            self.state = state
        }

        var item: WalletModule.Item {
            ._wallet(wallet: wallet)
        }

        var buttons: [WalletModule.Button: ButtonState] {
            var buttons = [WalletModule.Button: ButtonState]()

            if watchAccount {
                buttons[.address] = .enabled
            } else {
                let sendButtonState: ButtonState = state == .synced ? .enabled : .disabled

                buttons[.send] = sendButtonState
                buttons[.receive] = .enabled

                if wallet.token.swappable {
                    buttons[.swap] = sendButtonState
                }
            }

            buttons[.chart] = priceItem != nil ? .enabled : .disabled

            return buttons
        }
    }

}

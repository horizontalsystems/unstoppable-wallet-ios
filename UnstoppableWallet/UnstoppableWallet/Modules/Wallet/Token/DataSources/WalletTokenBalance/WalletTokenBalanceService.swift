import Combine
import Foundation
import HsExtensions
import RxSwift

class WalletTokenBalanceService {
    private let disposeBag = DisposeBag()

    private let coinPriceService: WalletCoinPriceService
    private let elementService: IWalletElementService
    private let cloudAccountBackupManager: CloudBackupManager
    private let balanceHiddenManager: BalanceHiddenManager
    private let reachabilityManager: IReachabilityManager

    private let account: Account
    let wallet: Wallet

    @PostPublished private(set) var item: BalanceItem?
    private let itemUpdatedSubject = PassthroughSubject<Void, Never>()
    private let balanceHiddenSubject = PassthroughSubject<Bool, Never>()

    private let queue = DispatchQueue(label: "\(AppConfig.label).wallet-token-balance-service", qos: .userInitiated)

    init(coinPriceService: WalletCoinPriceService, elementService: IWalletElementService,
         appManager: IAppManager, cloudAccountBackupManager: CloudBackupManager,
         balanceHiddenManager: BalanceHiddenManager, reachabilityManager: IReachabilityManager,
         account: Account, wallet: Wallet)
    {
        self.coinPriceService = coinPriceService
        self.elementService = elementService
        self.cloudAccountBackupManager = cloudAccountBackupManager
        self.balanceHiddenManager = balanceHiddenManager
        self.reachabilityManager = reachabilityManager

        self.account = account
        self.wallet = wallet

        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in
            self?.coinPriceService.refresh()
        }

        subscribe(disposeBag, balanceHiddenManager.balanceHiddenObservable) { [weak self] in
            self?.balanceHiddenSubject.send($0)
        }

        elementService.delegate = self
        coinPriceService.delegate = self
        coinPriceService.set(coinUids: Set([wallet.priceCoinUid].compactMap { $0 }))
        sync()
    }

    private func sync() {
        queue.async {
            self._sync()
        }
    }

    private func _sync() {
        let priceItemMap = coinPriceService.itemMap(coinUids: [wallet.priceCoinUid].compactMap { $0 })

        let item = BalanceItem(
            wallet: wallet,
            isMainNet: elementService.isMainNet(wallet: wallet) ?? fallbackIsMainNet,
            watchAccount: account.watchAccount,
            balanceData: elementService.balanceData(wallet: wallet) ?? fallbackBalanceData,
            state: elementService.state(wallet: wallet) ?? fallbackAdapterState
        )

        if let priceCoinUid = wallet.priceCoinUid {
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
    }
}

extension WalletTokenBalanceService: IWalletElementServiceDelegate {
    func didUpdate(elementState _: WalletModule.ElementState, elementService _: IWalletElementService) {
        queue.async { [weak self] in
            self?._sync()
        }
    }

    func didUpdateElements(elementService _: IWalletElementService) {}

    func didUpdate(isMainNet: Bool, wallet: Wallet) {
        guard wallet == self.wallet else {
            return
        }
        queue.async { [weak self] in
            self?.item?.isMainNet = isMainNet
            self?.itemUpdatedSubject.send()
        }
    }

    func didUpdate(balanceData: BalanceData, wallet: Wallet) {
        guard wallet == self.wallet else {
            return
        }
        queue.async { [weak self] in
            self?.item?.balanceData = balanceData
            self?.itemUpdatedSubject.send()
        }
    }

    func didUpdate(state: AdapterState, wallet: Wallet) {
        guard wallet == self.wallet else {
            return
        }
        queue.async { [weak self] in
            self?.item?.state = state
            self?.itemUpdatedSubject.send()
        }
    }
}

extension WalletTokenBalanceService: IWalletCoinPriceServiceDelegate {
    private func _handleUpdated(priceItemMap: [String: WalletCoinPriceService.Item], items _: [BalanceItem]) {
        queue.async { [weak self] in
            if let priceCoinUid = self?.wallet.priceCoinUid {
                self?.item?.priceItem = priceItemMap[priceCoinUid]
                self?.itemUpdatedSubject.send()
            }
        }
    }

    func didUpdate(itemsMap _: [String: WalletCoinPriceService.Item]?) {}
}

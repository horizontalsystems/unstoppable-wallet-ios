import RxSwift
import RxRelay
import CoinKit

class RestoreSelectService {
    private let accountType: AccountType
    private let coinManager: ICoinManager
    private let enableCoinsService: EnableCoinsService
    private let blockchainSettingsService: BlockchainSettingsService
    private let disposeBag = DisposeBag()

    private var featuredCoins = [Coin]()
    private var coins = [Coin]()
    private(set) var enabledCoins = Set<Coin>()
    private var filter: String?

    private let stateRelay = PublishRelay<State>()
    private let cancelEnableCoinRelay = PublishRelay<Coin>()
    private let canRestoreRelay = BehaviorRelay<Bool>(value: false)

    private(set) var state = State.empty {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(accountType: AccountType, coinManager: ICoinManager, enableCoinsService: EnableCoinsService, blockchainSettingsService: BlockchainSettingsService) {
        self.accountType = accountType
        self.coinManager = coinManager
        self.enableCoinsService = enableCoinsService
        self.blockchainSettingsService = blockchainSettingsService

        enableCoinsService.enableCoinsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] coins in
                    self?.enable(coins: coins, sortCoins: true)
                })
                .disposed(by: disposeBag)

        blockchainSettingsService.approveEnableCoinObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] coin in
                    self?.handleApproveEnable(coin: coin)
                })
                .disposed(by: disposeBag)

        blockchainSettingsService.rejectEnableCoinObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] coin in
                    self?.cancelEnableCoinRelay.accept(coin)
                })
                .disposed(by: disposeBag)

        (featuredCoins, coins) = coinManager.groupedCoins

        sortCoins()
        syncState()
    }

    private func item(coin: Coin) -> Item? {
        Item(coin: coin, enabled: enabledCoins.contains(coin))
    }

    private func filtered(coins: [Coin]) -> [Coin] {
        guard let filter = filter else {
            return coins
        }

        return coins.filter { coin in
            coin.title.localizedCaseInsensitiveContains(filter) || coin.code.localizedCaseInsensitiveContains(filter)
        }
    }

    private func sortCoins() {
        coins.sort { lhsCoin, rhsCoin in
            let lhsEnabled = enabledCoins.contains(lhsCoin)
            let rhsEnabled = enabledCoins.contains(rhsCoin)

            if lhsEnabled != rhsEnabled {
                return lhsEnabled
            }

            return lhsCoin.title.lowercased() < rhsCoin.title.lowercased()
        }
    }

    private func syncState() {
        let filteredFeaturedCoins = filtered(coins: featuredCoins)
        let filteredCoins = filtered(coins: coins)

        state = State(
                featuredItems: filteredFeaturedCoins.compactMap { item(coin: $0) },
                items: filteredCoins.compactMap { item(coin: $0) }
        )
    }

    private func syncCanRestore() {
        canRestoreRelay.accept(!enabledCoins.isEmpty)
    }

    private func handleApproveEnable(coin: Coin) {
        enable(coins: [coin])
        enableCoinsService.handle(coinType: coin.type, accountType: accountType)
    }

    private func enable(coins: [Coin], sortCoins: Bool = false) {
        for coin in coins {
            enabledCoins.insert(coin)
        }

        if sortCoins {
            self.sortCoins()
        }

        syncState()
        syncCanRestore()
    }

}

extension RestoreSelectService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var cancelEnableCoinObservable: Observable<Coin> {
        cancelEnableCoinRelay.asObservable()
    }

    var canRestoreObservable: Observable<Bool> {
        canRestoreRelay.asObservable()
    }

    func set(filter: String?) {
        self.filter = filter

        sortCoins()
        syncState()
    }

    func enable(coin: Coin) {
        blockchainSettingsService.approveEnable(coin: coin, accountOrigin: .restored)
    }

    func disable(coin: Coin) {
        enabledCoins.remove(coin)

        syncState()
        syncCanRestore()
    }

}

extension RestoreSelectService {

    struct State {
        let featuredItems: [Item]
        let items: [Item]

        static var empty: State {
            State(featuredItems: [], items: [])
        }
    }

    struct Item {
        let coin: Coin
        var enabled: Bool

        init(coin: Coin, enabled: Bool) {
            self.coin = coin
            self.enabled = enabled
        }
    }

}

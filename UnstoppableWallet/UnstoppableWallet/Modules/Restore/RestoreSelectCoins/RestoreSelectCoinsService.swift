import RxSwift
import RxRelay

class RestoreSelectCoinsService {
    private let predefinedAccountType: PredefinedAccountType
    private let accountType: AccountType
    private let coinManager: ICoinManager
    private let enableCoinsService: EnableCoinsService
    private let blockchainSettingsService: BlockchainSettingsService
    private let disposeBag = DisposeBag()

    private(set) var enabledCoins = Set<Coin>()

    private let stateRelay = PublishRelay<State>()
    private let cancelEnableCoinRelay = PublishRelay<Coin>()
    private let canRestoreRelay = BehaviorRelay<Bool>(value: false)

    var state = State.empty {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(predefinedAccountType: PredefinedAccountType, accountType: AccountType, coinManager: ICoinManager, enableCoinsService: EnableCoinsService, blockchainSettingsService: BlockchainSettingsService) {
        self.predefinedAccountType = predefinedAccountType
        self.accountType = accountType
        self.coinManager = coinManager
        self.enableCoinsService = enableCoinsService
        self.blockchainSettingsService = blockchainSettingsService

        enableCoinsService.enableCoinsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] coins in
                    self?.enable(coins: coins)
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

        syncState()
    }

    private func filteredCoins(coins: [Coin]) -> [Coin] {
        coins.filter { $0.type.predefinedAccountType == predefinedAccountType }
    }

    private func item(coin: Coin) -> Item? {
        Item(coin: coin, enabled: enabledCoins.contains(coin))
    }

    private func syncState() {
        let featuredCoins = filteredCoins(coins: coinManager.featuredCoins)
        let coins = filteredCoins(coins: coinManager.coins).filter { !featuredCoins.contains($0) }

        state = State(
                featuredItems: featuredCoins.compactMap { item(coin: $0) },
                items: coins.compactMap { item(coin: $0) }
        )
    }

    private func syncCanRestore() {
        canRestoreRelay.accept(!enabledCoins.isEmpty)
    }

    private func handleApproveEnable(coin: Coin) {
        enable(coins: [coin])
        enableCoinsService.handle(coinType: coin.type, accountType: accountType)
    }

    private func enable(coins: [Coin]) {
        for coin in coins {
            enabledCoins.insert(coin)
        }

        syncState()
        syncCanRestore()
    }

}

extension RestoreSelectCoinsService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var cancelEnableCoinObservable: Observable<Coin> {
        cancelEnableCoinRelay.asObservable()
    }

    var canRestoreObservable: Observable<Bool> {
        canRestoreRelay.asObservable()
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

extension RestoreSelectCoinsService {

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

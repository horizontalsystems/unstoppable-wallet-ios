import RxSwift
import RxRelay
import CoinKit

class RestoreSelectService {
    private let accountType: AccountType
    private let coinManager: ICoinManager
    private let enableCoinsService: EnableCoinsService
    private let coinSettingsService: CoinSettingsService
    private let disposeBag = DisposeBag()

    private var featuredCoins = [Coin]()
    private var coins = [Coin]()
    private(set) var enabledCoins = Set<ConfiguredCoin>()
    private var filter: String?

    private let stateRelay = PublishRelay<State>()
    private let cancelEnableCoinRelay = PublishRelay<Coin>()
    private let canRestoreRelay = BehaviorRelay<Bool>(value: false)

    private(set) var state = State.empty {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(accountType: AccountType, coinManager: ICoinManager, enableCoinsService: EnableCoinsService, coinSettingsService: CoinSettingsService) {
        self.accountType = accountType
        self.coinManager = coinManager
        self.enableCoinsService = enableCoinsService
        self.coinSettingsService = coinSettingsService

        enableCoinsService.enableCoinsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] coins in
                    let configuredCoins = coins.map { ConfiguredCoin(coin: $0) }
                    self?.enable(configuredCoins: configuredCoins, sortCoins: true)
                })
                .disposed(by: disposeBag)

        coinSettingsService.approveEnableCoinObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] coinWithSettings in
                    self?.handleApproveEnable(coin: coinWithSettings.coin, settingsData: coinWithSettings.settingsData)
                })
                .disposed(by: disposeBag)

        coinSettingsService.rejectEnableCoinObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] coin in
                    self?.cancelEnableCoinRelay.accept(coin)
                })
                .disposed(by: disposeBag)

        (featuredCoins, coins) = coinManager.groupedCoins

        sortCoins()
        syncState()
    }

    private func isEnabled(coin: Coin) -> Bool {
        enabledCoins.contains { $0.coin == coin }
    }

    private func item(coin: Coin) -> Item? {
        Item(coin: coin, enabled: isEnabled(coin: coin))
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
            let lhsEnabled = isEnabled(coin: lhsCoin)
            let rhsEnabled = isEnabled(coin: rhsCoin)

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

    private func configuredCoins(coin: Coin, settingsData: [[CoinSetting: String]]) -> [ConfiguredCoin] {
        if settingsData.isEmpty {
            return [ConfiguredCoin(coin: coin)]
        } else {
            return settingsData.map { ConfiguredCoin(coin: coin, settings: $0) }
        }
    }

    private func handleApproveEnable(coin: Coin, settingsData: [[CoinSetting: String]] = []) {
        enable(configuredCoins: configuredCoins(coin: coin, settingsData: settingsData))
        enableCoinsService.handle(coinType: coin.type, accountType: accountType)
    }

    private func enable(configuredCoins: [ConfiguredCoin], sortCoins: Bool = false) {
        for configuredCoin in configuredCoins {
            enabledCoins.insert(configuredCoin)
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
        if coin.type.coinSettings.isEmpty {
            handleApproveEnable(coin: coin)
        } else {
            coinSettingsService.approveEnable(coin: coin, settingsData: coin.type.defaultSettingsData)
        }
    }

    func disable(coin: Coin) {
        enabledCoins = enabledCoins.filter { $0.coin != coin }

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

import RxSwift
import RxRelay

class RestoreSelectCoinsService {
    private var predefinedAccountType: PredefinedAccountType
    private let coinManager: ICoinManager
    private let derivationSettingsManager: IDerivationSettingsManager

    private(set) var enabledCoins = Set<Coin>()

    private let stateRelay = PublishRelay<State>()
    private let canRestoreRelay = BehaviorRelay<Bool>(value: false)

    var state = State.empty {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(predefinedAccountType: PredefinedAccountType, coinManager: ICoinManager, derivationSettingsManager: IDerivationSettingsManager) {
        self.predefinedAccountType = predefinedAccountType
        self.coinManager = coinManager
        self.derivationSettingsManager = derivationSettingsManager

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

}

extension RestoreSelectCoinsService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var canRestoreObservable: Observable<Bool> {
        canRestoreRelay.asObservable()
    }

    func enable(coin: Coin, derivationSetting: DerivationSetting? = nil) throws {
        if let setting = derivationSettingsManager.setting(coinType: coin.type) {
            guard let derivationSetting = derivationSetting else {
                throw EnableCoinError.derivationNotConfirmed(currentDerivation: setting.derivation)
            }

            derivationSettingsManager.save(setting: derivationSetting)
        }

        enabledCoins.insert(coin)

        syncState()
        syncCanRestore()
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

    enum EnableCoinError: Error {
        case derivationNotConfirmed(currentDerivation: MnemonicDerivation)
    }

}

import RxSwift
import RxRelay
import CoinKit

class RestoreSelectService {
    private let accountType: AccountType
    private let accountFactory: IAccountFactory
    private let accountManager: IAccountManager
    private let walletManager: IWalletManager
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

    init(accountType: AccountType, accountFactory: IAccountFactory, accountManager: IAccountManager, walletManager: IWalletManager, coinManager: ICoinManager, enableCoinsService: EnableCoinsService, coinSettingsService: CoinSettingsService) {
        self.accountType = accountType
        self.accountFactory = accountFactory
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.coinManager = coinManager
        self.enableCoinsService = enableCoinsService
        self.coinSettingsService = coinSettingsService

        subscribe(disposeBag, enableCoinsService.enableCoinsObservable) { [weak self] coins in
            let configuredCoins = coins.map { ConfiguredCoin(coin: $0) }
            self?.enable(configuredCoins: configuredCoins, sortCoins: true)
        }
        subscribe(disposeBag, coinSettingsService.approveSettingsObservable) { [weak self] coinWithSettings in
            self?.handleApproveSettings(coin: coinWithSettings.coin, settingsArray: coinWithSettings.settingsArray)
        }
        subscribe(disposeBag, coinSettingsService.rejectApproveSettingsObservable) { [weak self] coin in
            self?.handleRejectApproveSettings(coin: coin)
        }

        (featuredCoins, coins) = coinManager.groupedCoins

        sortCoins()
        syncState()
    }

    private func isEnabled(coin: Coin) -> Bool {
        enabledCoins.contains { $0.coin == coin }
    }

    private func item(coin: Coin) -> Item {
        let enabled = isEnabled(coin: coin)

        return Item(
                coin: coin,
                hasSettings: enabled && !coin.type.coinSettingTypes.isEmpty,
                enabled: enabled
        )
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
                featuredItems: filteredFeaturedCoins.map { item(coin: $0) },
                items: filteredCoins.map { item(coin: $0) }
        )
    }

    private func syncCanRestore() {
        canRestoreRelay.accept(!enabledCoins.isEmpty)
    }

    private func configuredCoins(coin: Coin, settingsArray: [CoinSettings]) -> [ConfiguredCoin] {
        if settingsArray.isEmpty {
            return [ConfiguredCoin(coin: coin)]
        } else {
            return settingsArray.map { ConfiguredCoin(coin: coin, settings: $0) }
        }
    }

    private func handleApproveSettings(coin: Coin, settingsArray: [CoinSettings] = []) {
        let configuredCoins = self.configuredCoins(coin: coin, settingsArray: settingsArray)

        if isEnabled(coin: coin) {
            applySettings(coin: coin, configuredCoins: configuredCoins)
        } else {
            enable(configuredCoins: configuredCoins)
            enableCoinsService.handle(coinType: coin.type, accountType: accountType)
        }
    }

    private func handleRejectApproveSettings(coin: Coin) {
        if !isEnabled(coin: coin) {
            cancelEnableCoinRelay.accept(coin)
        }
    }

    private func applySettings(coin: Coin, configuredCoins: [ConfiguredCoin]) {
        let existingConfiguredCoins = enabledCoins.filter { $0.coin == coin }

        let newConfiguredCoins = configuredCoins.filter { !existingConfiguredCoins.contains($0) }
        let removedConfiguredCoins = existingConfiguredCoins.filter { !configuredCoins.contains($0) }

        for configuredCoin in newConfiguredCoins {
            enabledCoins.insert(configuredCoin)
        }

        for configuredCoin in removedConfiguredCoins {
            enabledCoins.remove(configuredCoin)
        }
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
        if coin.type.coinSettingTypes.isEmpty {
            handleApproveSettings(coin: coin)
        } else {
            coinSettingsService.approveSettings(coin: coin, settingsArray: coin.type.defaultSettingsArray)
        }
    }

    func disable(coin: Coin) {
        enabledCoins = enabledCoins.filter { $0.coin != coin }

        syncState()
        syncCanRestore()
    }

    func configure(coin: Coin) {
        guard !coin.type.coinSettingTypes.isEmpty else {
            return
        }

        let configuredCoins = enabledCoins.filter { $0.coin == coin }
        let settingsArray = configuredCoins.map { $0.settings }

        coinSettingsService.approveSettings(coin: coin, settingsArray: settingsArray)
    }

    func restore() {
        let account = accountFactory.account(type: accountType, origin: .restored, backedUp: true)
        accountManager.save(account: account)

        guard !enabledCoins.isEmpty else {
            return
        }

        let wallets = enabledCoins.map { Wallet(configuredCoin: $0, account: account) }
        walletManager.save(wallets: wallets)
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
        let hasSettings: Bool
        let enabled: Bool
    }

}

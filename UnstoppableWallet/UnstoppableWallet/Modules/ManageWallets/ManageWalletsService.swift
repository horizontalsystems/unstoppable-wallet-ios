import RxSwift
import RxRelay
import CoinKit

class ManageWalletsService {
    private let account: Account
    private let coinManager: ICoinManager
    private let walletManager: IWalletManager
    private let restoreSettingsService: RestoreSettingsService
    private let coinSettingsService: CoinSettingsService
    private let disposeBag = DisposeBag()

    private var featuredCoins = [Coin]()
    private var coins = [Coin]()
    private var wallets = Set<Wallet>()
    private var filter: String?

    private let stateRelay = PublishRelay<State>()
    private let cancelEnableCoinRelay = PublishRelay<Coin>()

    private var addedCoins = [Coin]()

    var state = State.empty {
        didSet {
            stateRelay.accept(state)
        }
    }

    init?(coinManager: ICoinManager, walletManager: IWalletManager, accountManager: IAccountManager, restoreSettingsService: RestoreSettingsService, coinSettingsService: CoinSettingsService) {
        guard let account = accountManager.activeAccount else {
            return nil
        }

        self.account = account
        self.coinManager = coinManager
        self.walletManager = walletManager
        self.restoreSettingsService = restoreSettingsService
        self.coinSettingsService = coinSettingsService

        subscribe(disposeBag, walletManager.activeWalletsUpdatedObservable) { [weak self] wallets in
            self?.handleUpdated(wallets: wallets)
        }
        subscribe(disposeBag, coinManager.coinsAddedObservable) { [weak self] coins in
            self?.handleAdded(coins: coins)
        }
        subscribe(disposeBag, restoreSettingsService.approveSettingsObservable) { [weak self] coinWithSettings in
            self?.handleApproveRestoreSettings(coin: coinWithSettings.coin, settings: coinWithSettings.settings)
        }
        subscribe(disposeBag, restoreSettingsService.rejectApproveSettingsObservable) { [weak self] coin in
            self?.handleRejectApproveRestoreSettings(coin: coin)
        }
        subscribe(disposeBag, coinSettingsService.approveSettingsObservable) { [weak self] coinWithSettings in
            self?.handleApproveCoinSettings(coin: coinWithSettings.coin, settingsArray: coinWithSettings.settingsArray)
        }
        subscribe(disposeBag, coinSettingsService.rejectApproveSettingsObservable) { [weak self] coin in
            self?.handleRejectApproveCoinSettings(coin: coin)
        }

        syncCoins()
        sync(wallets: walletManager.activeWallets)
        sortCoins()
        syncState()
    }

    private func syncCoins() {
        (featuredCoins, coins) = coinManager.groupedCoins
    }

    private func isEnabled(coin: Coin) -> Bool {
        wallets.contains { $0.coin == coin }
    }

    private func sortCoins() {
        coins.sort { lhsCoin, rhsCoin in
            let lhsAdded = addedCoins.contains(lhsCoin)
            let rhsAdded = addedCoins.contains(rhsCoin)

            if lhsAdded != rhsAdded {
                return lhsAdded
            }

            let lhsEnabled = isEnabled(coin: lhsCoin)
            let rhsEnabled = isEnabled(coin: rhsCoin)

            if lhsEnabled != rhsEnabled {
                return lhsEnabled
            }

            return lhsCoin.title.lowercased() < rhsCoin.title.lowercased()
        }
    }

    private func sync(wallets: [Wallet]) {
        self.wallets = Set(wallets)
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

    private func syncState() {
        let filteredFeaturedCoins = filtered(coins: featuredCoins)
        let filteredCoins = filtered(coins: coins)

        state = State(
                featuredItems: filteredFeaturedCoins.map { item(coin: $0) },
                items: filteredCoins.map { item(coin: $0) }
        )
    }

    private func handleUpdated(wallets: [Wallet]) {
        sync(wallets: wallets)
        syncState()
    }

    private func configuredCoins(coin: Coin, settingsArray: [CoinSettings]) -> [ConfiguredCoin] {
        if settingsArray.isEmpty {
            return [ConfiguredCoin(coin: coin)]
        } else {
            return settingsArray.map { ConfiguredCoin(coin: coin, settings: $0) }
        }
    }

    private func handleApproveRestoreSettings(coin: Coin, settings: RestoreSettings = [:]) {
        restoreSettingsService.save(settings: settings, account: account, coin: coin)

        if coin.type.coinSettingTypes.isEmpty {
            handleApproveCoinSettings(coin: coin)
        } else {
            coinSettingsService.approveSettings(coin: coin, settingsArray: coin.type.defaultSettingsArray)
        }
    }

    private func handleRejectApproveRestoreSettings(coin: Coin) {
        cancelEnableCoinRelay.accept(coin)
    }

    private func handleApproveCoinSettings(coin: Coin, settingsArray: [CoinSettings] = []) {
        let configuredCoins = self.configuredCoins(coin: coin, settingsArray: settingsArray)

        if isEnabled(coin: coin) {
            applySettings(coin: coin, configuredCoins: configuredCoins)
        } else {
            let wallets = configuredCoins.map { Wallet(configuredCoin: $0, account: account) }
            walletManager.save(wallets: wallets)
        }
    }

    private func handleRejectApproveCoinSettings(coin: Coin) {
        if !isEnabled(coin: coin) {
            cancelEnableCoinRelay.accept(coin)
        }
    }

    private func applySettings(coin: Coin, configuredCoins: [ConfiguredCoin]) {
        let existingWallets = wallets.filter { $0.coin == coin }
        let existingConfiguredCoins = existingWallets.map { $0.configuredCoin }

        let newConfiguredCoins = configuredCoins.filter { !existingConfiguredCoins.contains($0) }
        let removedWallets = existingWallets.filter { !configuredCoins.contains($0.configuredCoin) }

        let newWallets = newConfiguredCoins.map { Wallet(configuredCoin: $0, account: account) }

        if !newWallets.isEmpty || !removedWallets.isEmpty {
            walletManager.handle(newWallets: newWallets, deletedWallets: Array(removedWallets))
        }
    }

    private func handleAdded(coins: [Coin]) {
        addedCoins.append(contentsOf: coins)

        syncCoins()
        sortCoins()
        syncState()
    }

}

extension ManageWalletsService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var cancelEnableCoinObservable: Observable<Coin> {
        cancelEnableCoinRelay.asObservable()
    }

    func set(filter: String?) {
        self.filter = filter

        sortCoins()
        syncState()
    }

    func enable(coin: Coin) {
        if coin.type.restoreSettingTypes.isEmpty {
            handleApproveRestoreSettings(coin: coin)
        } else {
            restoreSettingsService.approveSettings(coin: coin, account: account)
        }
    }

    func disable(coin: Coin) {
        let walletsToDelete = wallets.filter { $0.coin == coin }
        walletManager.delete(wallets: Array(walletsToDelete))
    }

    func configure(coin: Coin) {
        guard !coin.type.coinSettingTypes.isEmpty else {
            return
        }

        let coinWallets = wallets.filter { $0.coin == coin }
        let settingsArray = coinWallets.map { $0.configuredCoin.settings }

        coinSettingsService.approveSettings(coin: coin, settingsArray: settingsArray)
    }

}

extension ManageWalletsService {

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

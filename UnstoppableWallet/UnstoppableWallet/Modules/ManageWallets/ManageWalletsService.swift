import RxSwift
import RxRelay
import MarketKit

class ManageWalletsService {
    private let account: Account
    private let coinManager: CoinManager
    private let walletManager: WalletManager
    private let enableCoinService: EnableCoinService
    private let disposeBag = DisposeBag()

    private var fullCoins = [FullCoin]()
    private var wallets = Set<Wallet>()
    private var filter: String = ""

    private let itemsRelay = PublishRelay<[Item]>()
    private let cancelEnableCoinRelay = PublishRelay<Coin>()

    private var addedCoins = [Coin]()

    var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init?(coinManager: CoinManager, walletManager: WalletManager, accountManager: IAccountManager, enableCoinService: EnableCoinService) {
        guard let account = accountManager.activeAccount else {
            return nil
        }

        self.account = account
        self.coinManager = coinManager
        self.walletManager = walletManager
        self.enableCoinService = enableCoinService

        subscribe(disposeBag, walletManager.activeWalletsUpdatedObservable) { [weak self] wallets in
            self?.handleUpdated(wallets: wallets)
        }
        subscribe(disposeBag, enableCoinService.enableCoinObservable) { [weak self] configuredPlatformsCoins, restoreSettings in
            self?.handleEnableCoin(configuredPlatformCoins: configuredPlatformsCoins, restoreSettings: restoreSettings)
        }
        subscribe(disposeBag, enableCoinService.cancelEnableCoinObservable) { [weak self] fullCoin in
            self?.handleCancelEnable(fullCoin: fullCoin)
        }

        sync(wallets: walletManager.activeWallets)
        syncFullCoins()
        sortFullCoins()
        syncState()
    }

    private func fetchFullCoins() -> [FullCoin] {
        do {
            if filter.trimmingCharacters(in: .whitespaces).isEmpty {
                return try coinManager.featuredFullCoins(enabledPlatformCoins: wallets.map { $0.platformCoin })
            } else {
                return try coinManager.fullCoins(filter: filter, limit: 20)
            }
        } catch {
            return []
        }
    }

    private func syncFullCoins() {
        fullCoins = fetchFullCoins()
    }

    private func isEnabled(coin: Coin) -> Bool {
        wallets.contains { $0.coin == coin }
    }

    private func sortFullCoins() {
        fullCoins.sort(filter: filter) { isEnabled(coin: $0) }
    }

    private func sync(wallets: [Wallet]) {
        self.wallets = Set(wallets)
    }

    private func hasSettingsOrPlatforms(supportedPlatforms: [Platform]) -> Bool {
        if supportedPlatforms.count == 1 {
            let platform = supportedPlatforms[0]
            return !platform.coinType.coinSettingTypes.isEmpty
        } else {
            return true
        }
    }

    private func item(fullCoin: FullCoin) -> Item {
        let supportedPlatforms = fullCoin.supportedPlatforms
        let fullCoin = FullCoin(coin: fullCoin.coin, platforms: supportedPlatforms)

        let itemState: ItemState

        if supportedPlatforms.isEmpty {
            itemState = .unsupported
        } else {
            let enabled = isEnabled(coin: fullCoin.coin)
            itemState = .supported(enabled: enabled, hasSettings: enabled && hasSettingsOrPlatforms(supportedPlatforms: supportedPlatforms))
        }

        return Item(fullCoin: fullCoin, state: itemState)
    }

    private func syncState() {
        items = fullCoins.map { item(fullCoin: $0) }
    }

    private func handleUpdated(wallets: [Wallet]) {
        sync(wallets: wallets)

        let newFullCoins = fetchFullCoins()

        if newFullCoins.count > fullCoins.count {
            fullCoins = newFullCoins
            sortFullCoins()
        }

        syncState()
    }

    private func handleEnableCoin(configuredPlatformCoins: [ConfiguredPlatformCoin], restoreSettings: RestoreSettings) {
        guard let coin = configuredPlatformCoins.first?.platformCoin.coin else {
            return
        }

        if !restoreSettings.isEmpty && configuredPlatformCoins.count == 1 {
            enableCoinService.save(restoreSettings: restoreSettings, account: account, coinType: configuredPlatformCoins[0].platformCoin.coinType)
        }

        let existingWallets = wallets.filter { $0.coin == coin }
        let existingConfiguredPlatformCoins = existingWallets.map { $0.configuredPlatformCoin }

        let newConfiguredCoins = configuredPlatformCoins.filter { !existingConfiguredPlatformCoins.contains($0) }
        let removedWallets = existingWallets.filter { !configuredPlatformCoins.contains($0.configuredPlatformCoin) }

        let newWallets = newConfiguredCoins.map { Wallet(configuredPlatformCoin: $0, account: account) }

        if !newWallets.isEmpty || !removedWallets.isEmpty {
            walletManager.handle(newWallets: newWallets, deletedWallets: Array(removedWallets))
        }
    }

    private func handleCancelEnable(fullCoin: FullCoin) {
        if !isEnabled(coin: fullCoin.coin) {
            cancelEnableCoinRelay.accept(fullCoin.coin)
        }
    }

}

extension ManageWalletsService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var cancelEnableCoinObservable: Observable<Coin> {
        cancelEnableCoinRelay.asObservable()
    }

    func set(filter: String) {
        self.filter = filter

        syncFullCoins()
        sortFullCoins()
        syncState()
    }

    func enable(uid: String) {
        guard let fullCoin = fullCoins.first(where: { $0.coin.uid == uid }) else {
            return
        }

        enableCoinService.enable(fullCoin: fullCoin, account: account)
    }

    func disable(uid: String) {
        let walletsToDelete = wallets.filter { $0.coin.uid == uid }
        walletManager.delete(wallets: Array(walletsToDelete))
    }

    func configure(uid: String) {
        guard let fullCoin = fullCoins.first(where: { $0.coin.uid == uid }) else {
            return
        }

        let coinWallets = wallets.filter { $0.coin.uid == uid }
        enableCoinService.configure(fullCoin: fullCoin, configuredPlatformCoins: coinWallets.map { $0.configuredPlatformCoin })
    }

}

extension ManageWalletsService {

    struct Item {
        let fullCoin: FullCoin
        let state: ItemState
    }

    enum ItemState {
        case unsupported
        case supported(enabled: Bool, hasSettings: Bool)
    }

}

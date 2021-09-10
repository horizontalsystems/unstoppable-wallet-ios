import RxSwift
import RxRelay
import MarketKit

class ManageWalletsService {
    private let account: Account
    private let coinManager: CoinManagerNew
    private let walletManager: WalletManagerNew
    private let enableCoinService: EnableCoinService
    private let disposeBag = DisposeBag()

    private var marketCoins = [MarketCoin]()
    private var wallets = Set<WalletNew>()
    private var filter: String = ""

    private let itemsRelay = PublishRelay<[Item]>()
    private let cancelEnableCoinRelay = PublishRelay<Coin>()

    private var addedCoins = [Coin]()

    var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init?(coinManager: CoinManagerNew, walletManager: WalletManagerNew, accountManager: IAccountManager, enableCoinService: EnableCoinService) {
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
        subscribe(disposeBag, enableCoinService.cancelEnableCoinObservable) { [weak self] coin in
            self?.handleCancelEnable(coin: coin)
        }

        sync(wallets: walletManager.activeWallets)
        syncMarketCoins()
        sortMarketCoins()
        syncState()
    }

    private func syncMarketCoins() {
        do {
            if filter.trimmingCharacters(in: .whitespaces).isEmpty {
                marketCoins = try coinManager.featuredMarketCoins(enabledCoinTypes: wallets.map { $0.coinType })
            } else {
                marketCoins = try coinManager.marketCoins(filter: filter, limit: 20)
            }
        } catch {
            // todo
        }
    }

    private func isEnabled(coin: Coin) -> Bool {
        wallets.contains { $0.coin == coin }
    }

    private func sortMarketCoins() {
        marketCoins.sort { lhsMarketCoin, rhsMarketCoin in
            let lhsEnabled = isEnabled(coin: lhsMarketCoin.coin)
            let rhsEnabled = isEnabled(coin: rhsMarketCoin.coin)

            if lhsEnabled != rhsEnabled {
                return lhsEnabled
            }

            let lhsMarketCapRank = lhsMarketCoin.coin.marketCapRank ?? Int.max
            let rhsMarketCapRank = rhsMarketCoin.coin.marketCapRank ?? Int.max

            if lhsMarketCapRank != rhsMarketCapRank {
                return lhsMarketCapRank < rhsMarketCapRank
            }

            return lhsMarketCoin.coin.name.lowercased() < rhsMarketCoin.coin.name.lowercased()
        }
    }

    private func sync(wallets: [WalletNew]) {
        self.wallets = Set(wallets)
    }

    private func hasSettingsOrPlatforms(marketCoin: MarketCoin) -> Bool {
        if marketCoin.platforms.count == 1 {
            let platform = marketCoin.platforms[0]
            return !platform.coinType.coinSettingTypes.isEmpty
        } else {
            return true
        }
    }

    private func item(marketCoin: MarketCoin) -> Item {
        let supportedPlatforms = marketCoin.platforms.filter { $0.coinType.isSupported }

        let marketCoin = MarketCoin(coin: marketCoin.coin, platforms: supportedPlatforms)

        let itemState: ItemState

        if marketCoin.platforms.isEmpty {
            itemState = .unsupported
        } else {
            let enabled = isEnabled(coin: marketCoin.coin)
            itemState = .supported(enabled: enabled, hasSettings: enabled && hasSettingsOrPlatforms(marketCoin: marketCoin))
        }

        return Item(marketCoin: marketCoin, state: itemState)
    }

    private func syncState() {
        items = marketCoins.map { item(marketCoin: $0) }
    }

    private func handleUpdated(wallets: [WalletNew]) {
        sync(wallets: wallets)

        let coins = marketCoins.map { $0.coin }
        if wallets.contains(where: { !coins.contains($0.coin) }) {
            syncMarketCoins()
            sortMarketCoins()
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

        let newWallets = newConfiguredCoins.map { WalletNew(configuredPlatformCoin: $0, account: account) }

        if !newWallets.isEmpty || !removedWallets.isEmpty {
            walletManager.handle(newWallets: newWallets, deletedWallets: Array(removedWallets))
        }
    }

    private func handleCancelEnable(coin: Coin) {
        if !isEnabled(coin: coin) {
            cancelEnableCoinRelay.accept(coin)
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

        syncMarketCoins()
        sortMarketCoins()
        syncState()
    }

    func enable(marketCoin: MarketCoin) {
        enableCoinService.enable(marketCoin: marketCoin, account: account)
    }

    func disable(coin: Coin) {
        let walletsToDelete = wallets.filter { $0.coin == coin }
        walletManager.delete(wallets: Array(walletsToDelete))
    }

    func configure(marketCoin: MarketCoin) {
        let coinWallets = wallets.filter { $0.coin == marketCoin.coin }
        enableCoinService.configure(marketCoin: marketCoin, configuredPlatformCoins: coinWallets.map { $0.configuredPlatformCoin })
    }

}

extension ManageWalletsService {

    struct Item {
        let marketCoin: MarketCoin
        let state: ItemState
    }

    enum ItemState {
        case unsupported
        case supported(enabled: Bool, hasSettings: Bool)
    }

}

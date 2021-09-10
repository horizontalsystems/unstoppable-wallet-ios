import RxSwift
import RxRelay
import MarketKit

class RestoreSelectService {
    private let accountType: AccountType
    private let accountFactory: AccountFactory
    private let accountManager: IAccountManager
    private let walletManager: WalletManagerNew
    private let coinManager: CoinManagerNew
    private let enableCoinService: EnableCoinService
    private let enableCoinsService: EnableCoinsService
    private let disposeBag = DisposeBag()

    private var marketCoins = [MarketCoin]()
    private(set) var enabledCoins = Set<ConfiguredPlatformCoin>()
    private var filter: String = ""

    private var restoreSettingsMap = [PlatformCoin: RestoreSettings]()

    private let cancelEnableCoinRelay = PublishRelay<Coin>()
    private let canRestoreRelay = BehaviorRelay<Bool>(value: false)

    private let itemsRelay = PublishRelay<[Item]>()
    var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(accountType: AccountType, accountFactory: AccountFactory, accountManager: IAccountManager, walletManager: WalletManagerNew, coinManager: CoinManagerNew, enableCoinService: EnableCoinService, enableCoinsService: EnableCoinsService) {
        self.accountType = accountType
        self.accountFactory = accountFactory
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.coinManager = coinManager
        self.enableCoinService = enableCoinService
        self.enableCoinsService = enableCoinsService

        subscribe(disposeBag, enableCoinsService.enableCoinTypesObservable) { [weak self] coinTypes in
            self?.handleEnable(coinTypes: coinTypes)
        }
        subscribe(disposeBag, enableCoinService.enableCoinObservable) { [weak self] configuredPlatformsCoins, restoreSettings in
            self?.handleEnableCoin(configuredPlatformCoins: configuredPlatformsCoins, restoreSettings: restoreSettings)
        }
        subscribe(disposeBag, enableCoinService.cancelEnableCoinObservable) { [weak self] coin in
            self?.handleCancelEnable(coin: coin)
        }

        syncMarketCoins()
        sortMarketCoins()
        syncState()
    }

    private func syncMarketCoins() {
        do {
            if filter.trimmingCharacters(in: .whitespaces).isEmpty {
                marketCoins = try coinManager.featuredMarketCoins(enabledCoinTypes: enabledCoins.map { $0.platformCoin.coinType })
            } else {
                marketCoins = try coinManager.marketCoins(filter: filter, limit: 20)
            }
        } catch {
            // todo
        }
    }

    private func isEnabled(coin: Coin) -> Bool {
        enabledCoins.contains { $0.platformCoin.coin == coin }
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

    private func syncState() {
        items = marketCoins.map { item(marketCoin: $0) }
    }

    private func syncCanRestore() {
        canRestoreRelay.accept(!enabledCoins.isEmpty)
    }

    private func handleEnableCoin(configuredPlatformCoins: [ConfiguredPlatformCoin], restoreSettings: RestoreSettings) {
        guard let platformCoin = configuredPlatformCoins.first?.platformCoin else {
            return
        }

        if !restoreSettings.isEmpty {
            restoreSettingsMap[platformCoin] = restoreSettings
        }

        let existingConfiguredPlatformCoins = enabledCoins.filter { $0.platformCoin.coin == platformCoin.coin }

        let newConfiguredPlatformCoins = configuredPlatformCoins.filter { !existingConfiguredPlatformCoins.contains($0) }
        let removedConfiguredPlatformCoins = existingConfiguredPlatformCoins.filter { !configuredPlatformCoins.contains($0) }

        for configuredPlatformCoin in newConfiguredPlatformCoins {
            enabledCoins.insert(configuredPlatformCoin)
        }

        for configuredPlatformCoin in removedConfiguredPlatformCoins {
            enabledCoins.remove(configuredPlatformCoin)
        }

        syncCanRestore()
        syncState()
        enableCoinsService.handle(coinTypes: newConfiguredPlatformCoins.map { $0.platformCoin.coinType }, accountType: accountType)
    }

    private func handleCancelEnable(coin: Coin) {
        if !isEnabled(coin: coin) {
            cancelEnableCoinRelay.accept(coin)
        }
    }

    private func handleEnable(coinTypes: [CoinType]) {
        do {
            let platformCoins = try coinManager.platformCoins(coinTypeIds: coinTypes.map { $0.id })

            for platformCoin in platformCoins {
                enabledCoins.insert(ConfiguredPlatformCoin(platformCoin: platformCoin))
            }

            syncMarketCoins()
            sortMarketCoins()
            syncState()
        } catch {
            // todo
        }
    }

}

extension RestoreSelectService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var cancelEnableCoinObservable: Observable<Coin> {
        cancelEnableCoinRelay.asObservable()
    }

    var canRestoreObservable: Observable<Bool> {
        canRestoreRelay.asObservable()
    }

    func set(filter: String) {
        self.filter = filter

        syncMarketCoins()
        sortMarketCoins()
        syncState()
    }

    func enable(marketCoin: MarketCoin) {
        enableCoinService.enable(marketCoin: marketCoin)
    }

    func disable(coin: Coin) {
        enabledCoins = enabledCoins.filter { $0.platformCoin.coin != coin }

        syncState()
        syncCanRestore()
    }

    func configure(marketCoin: MarketCoin) {
        enableCoinService.configure(marketCoin: marketCoin, configuredPlatformCoins: enabledCoins.filter { $0.platformCoin.coin == marketCoin.coin })
    }

    func restore() {
        let account = accountFactory.account(type: accountType, origin: .restored)
        accountManager.save(account: account)

        for (platformCoin, settings) in restoreSettingsMap {
            enableCoinService.save(restoreSettings: settings, account: account, coinType: platformCoin.coinType)
        }

        guard !enabledCoins.isEmpty else {
            return
        }

        let wallets = enabledCoins.map { WalletNew(configuredPlatformCoin: $0, account: account) }
        walletManager.save(wallets: wallets)
    }

}

extension RestoreSelectService {

    struct Item {
        let marketCoin: MarketCoin
        let state: ItemState
    }

    enum ItemState {
        case unsupported
        case supported(enabled: Bool, hasSettings: Bool)
    }

}

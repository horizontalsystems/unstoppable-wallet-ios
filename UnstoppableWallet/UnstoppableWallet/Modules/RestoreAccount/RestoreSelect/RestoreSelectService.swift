import RxSwift
import RxRelay
import MarketKit

class RestoreSelectService {
    private let accountType: AccountType
    private let accountFactory: AccountFactory
    private let accountManager: IAccountManager
    private let walletManager: WalletManager
    private let coinManager: CoinManager
    private let enableCoinService: EnableCoinService
    private let enableCoinsService: EnableCoinsService
    private let disposeBag = DisposeBag()

    private var fullCoins = [FullCoin]()
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

    private let autoEnabledItemsRelay = PublishRelay<Int>()

    init(accountType: AccountType, accountFactory: AccountFactory, accountManager: IAccountManager, walletManager: WalletManager, coinManager: CoinManager, enableCoinService: EnableCoinService, enableCoinsService: EnableCoinsService) {
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

        syncFullCoins()
        sortFullCoins()
        syncState()
    }

    private func syncFullCoins() {
        do {
            if filter.trimmingCharacters(in: .whitespaces).isEmpty {
                fullCoins = try coinManager.featuredFullCoins(enabledPlatformCoins: enabledCoins.map { $0.platformCoin })
            } else {
                fullCoins = try coinManager.fullCoins(filter: filter, limit: 20)
            }
        } catch {
            // todo
        }
    }

    private func isEnabled(coin: Coin) -> Bool {
        enabledCoins.contains { $0.platformCoin.coin == coin }
    }

    private func hasSettingsOrPlatforms(fullCoin: FullCoin) -> Bool {
        if fullCoin.platforms.count == 1 {
            let platform = fullCoin.platforms[0]
            return !platform.coinType.coinSettingTypes.isEmpty
        } else {
            return true
        }
    }

    private func item(fullCoin: FullCoin) -> Item {
        let supportedPlatforms = fullCoin.platforms.filter { $0.coinType.isSupported }

        let fullCoin = FullCoin(coin: fullCoin.coin, platforms: supportedPlatforms)

        let itemState: ItemState

        if fullCoin.platforms.isEmpty {
            itemState = .unsupported
        } else {
            let enabled = isEnabled(coin: fullCoin.coin)
            itemState = .supported(enabled: enabled, hasSettings: enabled && hasSettingsOrPlatforms(fullCoin: fullCoin))
        }

        return Item(fullCoin: fullCoin, state: itemState)
    }

    private func sortFullCoins() {
        fullCoins.sort(filter: filter) { isEnabled(coin: $0) }
    }

    private func syncState() {
        items = fullCoins.map { item(fullCoin: $0) }
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
            var newCoinsCount = 0
            for platformCoin in try coinManager.platformCoins(coinTypeIds: coinTypes.map { $0.id }) {
                let (inserted, _) = enabledCoins.insert(ConfiguredPlatformCoin(platformCoin: platformCoin))
                if inserted {
                    newCoinsCount += 1
                }
            }

            autoEnabledItemsRelay.accept(newCoinsCount)

            syncFullCoins()
            sortFullCoins()
            syncState()
        } catch {
            // todo
        }
    }

}

extension RestoreSelectService {

    var autoEnabledItemsObservable: Observable<Int> {
        autoEnabledItemsRelay.asObservable()
    }

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

        syncFullCoins()
        sortFullCoins()
        syncState()
    }

    func enable(fullCoin: FullCoin) {
        enableCoinService.enable(fullCoin: fullCoin)
    }

    func disable(coin: Coin) {
        enabledCoins = enabledCoins.filter { $0.platformCoin.coin != coin }

        syncState()
        syncCanRestore()
    }

    func configure(fullCoin: FullCoin) {
        enableCoinService.configure(fullCoin: fullCoin, configuredPlatformCoins: enabledCoins.filter { $0.platformCoin.coin == fullCoin.coin })
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

        let wallets = enabledCoins.map { Wallet(configuredPlatformCoin: $0, account: account) }
        walletManager.save(wallets: wallets)
    }

}

extension RestoreSelectService {

    struct Item {
        let fullCoin: FullCoin
        let state: ItemState
    }

    enum ItemState {
        case unsupported
        case supported(enabled: Bool, hasSettings: Bool)
    }

}

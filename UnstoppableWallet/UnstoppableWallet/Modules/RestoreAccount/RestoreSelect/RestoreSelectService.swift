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
    private let disposeBag = DisposeBag()

    private var internalItems = [InternalItem]()
    private(set) var enabledCoins = Set<ConfiguredPlatformCoin>()

    private var restoreSettingsMap = [PlatformCoin: RestoreSettings]()

    private let cancelEnableBlockchainRelay = PublishRelay<RestoreSelectModule.Blockchain>()
    private let canRestoreRelay = BehaviorRelay<Bool>(value: false)

    private let itemsRelay = PublishRelay<[Item]>()
    var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(accountType: AccountType, accountFactory: AccountFactory, accountManager: IAccountManager, walletManager: WalletManager, coinManager: CoinManager, enableCoinService: EnableCoinService) {
        self.accountType = accountType
        self.accountFactory = accountFactory
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.coinManager = coinManager
        self.enableCoinService = enableCoinService

        subscribe(disposeBag, enableCoinService.enableCoinObservable) { [weak self] configuredPlatformsCoins, restoreSettings in
            self?.handleEnableCoin(configuredPlatformCoins: configuredPlatformsCoins, restoreSettings: restoreSettings)
        }
        subscribe(disposeBag, enableCoinService.cancelEnableCoinObservable) { [weak self] fullCoin in
            self?.handleCancelEnable(fullCoin: fullCoin)
        }

        syncInternalItems()
        syncState()
    }

    private func syncInternalItems() {
        do {
            let platformCoins = try coinManager.platformCoins(coinTypes: RestoreSelectModule.Blockchain.all.map { $0.coinType })

            internalItems = RestoreSelectModule.Blockchain.all.compactMap { blockchain in
                guard let platformCoin = platformCoins.first(where: { $0.coinType == blockchain.coinType }) else {
                    return nil
                }

                return InternalItem(blockchain: blockchain, platformCoin: platformCoin)
            }
        } catch {
            // todo
        }
    }

    private func isEnabled(internalItem: InternalItem) -> Bool {
        enabledCoins.contains { $0.platformCoin == internalItem.platformCoin }
    }

    private func hasSettings(platformCoin: PlatformCoin) -> Bool {
        !platformCoin.coinType.coinSettingTypes.isEmpty
    }

    private func item(internalItem: InternalItem) -> Item {
        let itemState: ItemState

        let enabled = isEnabled(internalItem: internalItem)
        itemState = .supported(enabled: enabled, hasSettings: enabled && hasSettings(platformCoin: internalItem.platformCoin))

        return Item(blockchain: internalItem.blockchain, state: itemState)
    }

    private func syncState() {
        items = internalItems.map { item(internalItem: $0) }
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

        let existingConfiguredPlatformCoins = enabledCoins.filter { $0.platformCoin == platformCoin }

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
    }

    private func handleCancelEnable(fullCoin: FullCoin) {
        guard let internalItem = internalItems.first(where: { fullCoin.supportedPlatforms.contains($0.platformCoin.platform) }) else {
            return
        }

        if !isEnabled(internalItem: internalItem) {
            cancelEnableBlockchainRelay.accept(internalItem.blockchain)
        }
    }

}

extension RestoreSelectService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var cancelEnableBlockchainObservable: Observable<RestoreSelectModule.Blockchain> {
        cancelEnableBlockchainRelay.asObservable()
    }

    var canRestoreObservable: Observable<Bool> {
        canRestoreRelay.asObservable()
    }

    func enable(blockchainUid: String) {
        guard let internalItem = internalItems.first(where: { $0.blockchain.uid == blockchainUid }) else {
            return
        }

        enableCoinService.enable(fullCoin: internalItem.platformCoin.fullCoin)
    }

    func disable(blockchainUid: String) {
        guard let internalItem = internalItems.first(where: { $0.blockchain.uid == blockchainUid }) else {
            return
        }

        enabledCoins = enabledCoins.filter { $0.platformCoin != internalItem.platformCoin }

        syncState()
        syncCanRestore()
    }

    func configure(blockchainUid: String) {
        guard let internalItem = internalItems.first(where: { $0.blockchain.uid == blockchainUid }) else {
            return
        }

        enableCoinService.configure(fullCoin: internalItem.platformCoin.fullCoin, configuredPlatformCoins: enabledCoins.filter { $0.platformCoin == internalItem.platformCoin })
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

    struct InternalItem {
        let blockchain: RestoreSelectModule.Blockchain
        let platformCoin: PlatformCoin
    }

    struct Item {
        let blockchain: RestoreSelectModule.Blockchain
        let state: ItemState
    }

    enum ItemState {
        case unsupported
        case supported(enabled: Bool, hasSettings: Bool)
    }

}

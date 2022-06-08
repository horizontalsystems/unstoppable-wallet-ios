import RxSwift
import RxRelay
import MarketKit

class RestoreSelectService {
    private let accountName: String
    private let accountType: AccountType
    private let accountFactory: AccountFactory
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let marketKit: MarketKit.Kit
    private let evmBlockchainManager: EvmBlockchainManager
    private let enableCoinService: EnableCoinService
    private let disposeBag = DisposeBag()

    private var internalItems = [InternalItem]()
    private(set) var enabledCoins = Set<ConfiguredToken>()

    private var restoreSettingsMap = [Token: RestoreSettings]()

    private let cancelEnableBlockchainRelay = PublishRelay<RestoreSelectModule.Blockchain>()
    private let canRestoreRelay = BehaviorRelay<Bool>(value: false)

    private let itemsRelay = PublishRelay<[Item]>()
    var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(accountName: String, accountType: AccountType, accountFactory: AccountFactory, accountManager: AccountManager, walletManager: WalletManager, marketKit: MarketKit.Kit, evmBlockchainManager: EvmBlockchainManager, enableCoinService: EnableCoinService) {
        self.accountName = accountName
        self.accountType = accountType
        self.accountFactory = accountFactory
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.marketKit = marketKit
        self.evmBlockchainManager = evmBlockchainManager
        self.enableCoinService = enableCoinService

        subscribe(disposeBag, enableCoinService.enableCoinObservable) { [weak self] configuredTokens, restoreSettings in
            self?.handleEnableCoin(configuredTokens: configuredTokens, restoreSettings: restoreSettings)
        }
        subscribe(disposeBag, enableCoinService.cancelEnableCoinObservable) { [weak self] fullCoin in
            self?.handleCancelEnable(fullCoin: fullCoin)
        }

        syncInternalItems()
        syncState()
    }

    private func syncInternalItems() {
        do {
            let tokens = try marketKit.tokens(queries: RestoreSelectModule.Blockchain.all.map { $0.tokenQuery })

            internalItems = RestoreSelectModule.Blockchain.all.compactMap { blockchain in
                guard let token = tokens.first(where: { $0.tokenQuery == blockchain.tokenQuery }) else {
                    return nil
                }

                return InternalItem(blockchain: blockchain, token: token)
            }
        } catch {
            // todo
        }
    }

    private func isEnabled(internalItem: InternalItem) -> Bool {
        enabledCoins.contains { $0.token == internalItem.token }
    }

    private func hasSettings(token: Token) -> Bool {
        !token.blockchainType.coinSettingTypes.isEmpty
    }

    private func item(internalItem: InternalItem) -> Item {
        let enabled = isEnabled(internalItem: internalItem)

        return Item(
                blockchain: internalItem.blockchain,
                enabled: enabled,
                hasSettings: enabled && hasSettings(token: internalItem.token)
        )
    }

    private func syncState() {
        items = internalItems.map { item(internalItem: $0) }
    }

    private func syncCanRestore() {
        canRestoreRelay.accept(!enabledCoins.isEmpty)
    }

    private func handleEnableCoin(configuredTokens: [ConfiguredToken], restoreSettings: RestoreSettings) {
        guard let token = configuredTokens.first?.token else {
            return
        }

        if !restoreSettings.isEmpty {
            restoreSettingsMap[token] = restoreSettings
        }

        let existingConfiguredTokens = enabledCoins.filter { $0.token == token }

        let newConfiguredTokens = configuredTokens.filter { !existingConfiguredTokens.contains($0) }
        let removedConfiguredTokens = existingConfiguredTokens.filter { !configuredTokens.contains($0) }

        for configuredToken in newConfiguredTokens {
            enabledCoins.insert(configuredToken)
        }

        for configuredToken in removedConfiguredTokens {
            enabledCoins.remove(configuredToken)
        }

        syncCanRestore()
        syncState()
    }

    private func handleCancelEnable(fullCoin: FullCoin) {
        guard let internalItem = internalItems.first(where: { fullCoin.supportedTokens.contains($0.token) }) else {
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

        enableCoinService.enable(fullCoin: internalItem.token.fullCoin)
    }

    func disable(blockchainUid: String) {
        guard let internalItem = internalItems.first(where: { $0.blockchain.uid == blockchainUid }) else {
            return
        }

        enabledCoins = enabledCoins.filter { $0.token != internalItem.token }

        syncState()
        syncCanRestore()
    }

    func configure(blockchainUid: String) {
        guard let internalItem = internalItems.first(where: { $0.blockchain.uid == blockchainUid }) else {
            return
        }

        enableCoinService.configure(fullCoin: internalItem.token.fullCoin, configuredTokens: enabledCoins.filter { $0.token == internalItem.token })
    }

    func restore() {
        let account = accountFactory.account(name: accountName, type: accountType, origin: .restored)
        accountManager.save(account: account)

        for (token, settings) in restoreSettingsMap {
            enableCoinService.save(restoreSettings: settings, account: account, blockchainType: token.blockchainType)
        }

        for item in items {
            guard item.enabled else {
                continue
            }

            switch item.blockchain {
            case .evm(let blockchainType):
                evmBlockchainManager.evmAccountManager(blockchainType: blockchainType).markAutoEnable(account: account)
            default: ()
            }
        }

        guard !enabledCoins.isEmpty else {
            return
        }

        let wallets = enabledCoins.map { Wallet(configuredToken: $0, account: account) }
        walletManager.save(wallets: wallets)
    }

}

extension RestoreSelectService {

    struct InternalItem {
        let blockchain: RestoreSelectModule.Blockchain
        let token: Token
    }

    struct Item {
        let blockchain: RestoreSelectModule.Blockchain
        let enabled: Bool
        let hasSettings: Bool
    }

}

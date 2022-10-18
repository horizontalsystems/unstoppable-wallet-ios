import RxSwift
import RxRelay
import MarketKit

class RestoreSelectService {
    private let blockchainTypes: [BlockchainType] = [
        .bitcoin,
        .bitcoinCash,
        .litecoin,
        .dash,
        .zcash,
        .ethereum,
        .polygon,
        .avalanche,
        .optimism,
        .arbitrumOne,
        .binanceSmartChain,
        .binanceChain,
    ]

    private let accountType: AccountType
    private let accountFactory: AccountFactory
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let evmAccountRestoreStateManager: EvmAccountRestoreStateManager
    private let marketKit: MarketKit.Kit
    private let enableCoinService: EnableCoinService
    private let disposeBag = DisposeBag()

    private var tokens = [Token]()
    private(set) var enabledConfiguredTokens = Set<ConfiguredToken>()

    private var restoreSettingsMap = [Token: RestoreSettings]()

    private let cancelEnableBlockchainRelay = PublishRelay<BlockchainType>()
    private let canRestoreRelay = BehaviorRelay<Bool>(value: false)

    private let itemsRelay = PublishRelay<[Item]>()
    var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(accountType: AccountType, accountFactory: AccountFactory, accountManager: AccountManager, walletManager: WalletManager, evmAccountRestoreStateManager: EvmAccountRestoreStateManager, marketKit: MarketKit.Kit, enableCoinService: EnableCoinService) {
        self.accountType = accountType
        self.accountFactory = accountFactory
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.evmAccountRestoreStateManager = evmAccountRestoreStateManager
        self.marketKit = marketKit
        self.enableCoinService = enableCoinService

        subscribe(disposeBag, enableCoinService.enableCoinObservable) { [weak self] configuredTokens, restoreSettings in
            self?.handleEnableCoin(configuredTokens: configuredTokens, restoreSettings: restoreSettings)
        }
        subscribe(disposeBag, enableCoinService.disableCoinObservable) { [weak self] coin in
            self?.handleDisable(coin: coin)
        }
        subscribe(disposeBag, enableCoinService.cancelEnableCoinObservable) { [weak self] fullCoin in
            self?.handleCancelEnable(fullCoin: fullCoin)
        }

        syncInternalItems()
        syncState()
    }

    private func syncInternalItems() {
        do {
            let allowedBlockchainTypes = blockchainTypes.filter { $0.supports(accountType: self.accountType)}

            let tokens = try marketKit.tokens(queries: allowedBlockchainTypes.map { TokenQuery(blockchainType: $0, tokenType: .native) })

            self.tokens = allowedBlockchainTypes.sorted { $0.order < $1.order }.compactMap { type in
                tokens.first { $0.blockchainType == type }
            }
        } catch {
            // todo
        }
    }

    private func isEnabled(token: Token) -> Bool {
        enabledConfiguredTokens.contains { $0.token == token }
    }

    private func hasSettings(token: Token) -> Bool {
        token.blockchainType.coinSettingType != nil
    }

    private func item(token: Token) -> Item {
        let enabled = isEnabled(token: token)

        return Item(
                blockchain: token.blockchain,
                enabled: enabled,
                hasSettings: enabled && hasSettings(token: token)
        )
    }

    private func syncState() {
        items = tokens.map { item(token: $0) }
    }

    private func syncCanRestore() {
        canRestoreRelay.accept(!enabledConfiguredTokens.isEmpty)
    }

    private func handleEnableCoin(configuredTokens: [ConfiguredToken], restoreSettings: RestoreSettings) {
        guard let token = configuredTokens.first?.token else {
            return
        }

        if !restoreSettings.isEmpty {
            restoreSettingsMap[token] = restoreSettings
        }

        let existingConfiguredTokens = enabledConfiguredTokens.filter { $0.token == token }

        let newConfiguredTokens = configuredTokens.filter { !existingConfiguredTokens.contains($0) }
        let removedConfiguredTokens = existingConfiguredTokens.filter { !configuredTokens.contains($0) }

        for configuredToken in newConfiguredTokens {
            enabledConfiguredTokens.insert(configuredToken)
        }

        for configuredToken in removedConfiguredTokens {
            enabledConfiguredTokens.remove(configuredToken)
        }

        syncCanRestore()
        syncState()
    }

    private func handleDisable(coin: Coin) {
        for token in restoreSettingsMap.keys {
            if token.coin == coin {
                restoreSettingsMap.removeValue(forKey: token)
            }
        }

        for configuredToken in enabledConfiguredTokens {
            if configuredToken.token.coin == coin {
                enabledConfiguredTokens.remove(configuredToken)
            }
        }

        syncCanRestore()
        syncState()
    }

    private func handleCancelEnable(fullCoin: FullCoin) {
        guard let token = tokens.first(where: { fullCoin.supportedTokens.contains($0) }) else {
            return
        }

        if !isEnabled(token: token) {
            cancelEnableBlockchainRelay.accept(token.blockchainType)
        }
    }

}

extension RestoreSelectService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var cancelEnableBlockchainObservable: Observable<BlockchainType> {
        cancelEnableBlockchainRelay.asObservable()
    }

    var canRestoreObservable: Observable<Bool> {
        canRestoreRelay.asObservable()
    }

    func enable(blockchainUid: String) {
        guard let token = tokens.first(where: { $0.blockchain.uid == blockchainUid }) else {
            return
        }

        enableCoinService.enable(fullCoin: token.fullCoin, accountType: accountType)
    }

    func disable(blockchainUid: String) {
        guard let token = tokens.first(where: { $0.blockchain.uid == blockchainUid }) else {
            return
        }

        enabledConfiguredTokens = enabledConfiguredTokens.filter { $0.token != token }

        syncState()
        syncCanRestore()
    }

    func configure(blockchainUid: String) {
        guard let token = tokens.first(where: { $0.blockchain.uid == blockchainUid }) else {
            return
        }

        enableCoinService.configure(fullCoin: token.fullCoin, accountType: accountType, configuredTokens: enabledConfiguredTokens.filter { $0.token == token })
    }

    func restore() {
        let account = accountFactory.account(type: accountType, origin: .restored)
        accountManager.save(account: account)

        for (token, settings) in restoreSettingsMap {
            enableCoinService.save(restoreSettings: settings, account: account, blockchainType: token.blockchainType)
        }

        guard !enabledConfiguredTokens.isEmpty else {
            return
        }

        for configuredToken in enabledConfiguredTokens {
            evmAccountRestoreStateManager.setRestored(account: account, blockchainType: configuredToken.token.blockchainType)
        }

        let wallets = enabledConfiguredTokens.map { Wallet(configuredToken: $0, account: account) }
        walletManager.save(wallets: wallets)
    }

}

extension RestoreSelectService {

    struct Item {
        let blockchain: Blockchain
        let enabled: Bool
        let hasSettings: Bool
    }

}

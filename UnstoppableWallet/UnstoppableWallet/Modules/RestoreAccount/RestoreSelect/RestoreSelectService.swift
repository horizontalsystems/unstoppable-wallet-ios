import RxSwift
import RxRelay
import MarketKit

class RestoreSelectService {

    private let accountName: String
    private let accountType: AccountType
    private let isManualBackedUp: Bool
    private let accountFactory: AccountFactory
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let evmAccountRestoreStateManager: EvmAccountRestoreStateManager
    private let marketKit: MarketKit.Kit
    private let enableCoinService: EnableCoinService
    private let disposeBag = DisposeBag()

    private var tokens = [Token]()
    private(set) var enabledTokens = Set<Token>()

    private var restoreSettingsMap = [Token: RestoreSettings]()

    private let cancelEnableBlockchainRelay = PublishRelay<BlockchainType>()
    private let canRestoreRelay = BehaviorRelay<Bool>(value: false)

    private let itemsRelay = PublishRelay<[Item]>()
    var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(accountName: String, accountType: AccountType, isManualBackedUp: Bool, accountFactory: AccountFactory, accountManager: AccountManager, walletManager: WalletManager, evmAccountRestoreStateManager: EvmAccountRestoreStateManager, marketKit: MarketKit.Kit, enableCoinService: EnableCoinService) {
        self.accountName = accountName
        self.accountType = accountType
        self.isManualBackedUp = isManualBackedUp
        self.accountFactory = accountFactory
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.evmAccountRestoreStateManager = evmAccountRestoreStateManager
        self.marketKit = marketKit
        self.enableCoinService = enableCoinService

        subscribe(disposeBag, enableCoinService.enableCoinObservable) { [weak self] tokens, restoreSettings in
            self?.handleEnableCoin(tokens: tokens, restoreSettings: restoreSettings)
        }
        subscribe(disposeBag, enableCoinService.disableCoinObservable) { [weak self] coin in
            self?.handleDisable(coin: coin)
        }
        subscribe(disposeBag, enableCoinService.cancelEnableCoinObservable) { [weak self] coin in
            self?.handleCancelEnable(coin: coin)
        }

        syncInternalItems()
        syncState()
    }

    private func syncInternalItems() {
        do {
            let allowedBlockchainTypes = BlockchainType.supported.filter { $0.supports(accountType: accountType) }

            let tokenQueries = allowedBlockchainTypes
                    .map { $0.nativeTokenQueries }
                    .flatMap { $0 }

            tokens = try marketKit.tokens(queries: tokenQueries)
        } catch {
            // todo
        }
    }

    private func isEnabled(blockchain: Blockchain) -> Bool {
        enabledTokens.contains { $0.blockchain == blockchain }
    }

    private func hasSettings(blockchain: Blockchain) -> Bool {
        tokens.filter { $0.blockchain == blockchain }.count > 1
    }

    private func item(blockchain: Blockchain) -> Item {
        let enabled = isEnabled(blockchain: blockchain)

        return Item(
                blockchain: blockchain,
                enabled: enabled,
                hasSettings: enabled && hasSettings(blockchain: blockchain)
        )
    }

    private func syncState() {
        let blockchains = Set(tokens.map { $0.blockchain })
        items = blockchains.sorted { $0.type.order < $1.type.order }.map { item(blockchain: $0) }
    }

    private func syncCanRestore() {
        canRestoreRelay.accept(!enabledTokens.isEmpty)
    }

    private func handleEnableCoin(tokens: [Token], restoreSettings: RestoreSettings) {
        guard let token = tokens.first else {
            return
        }

        if !restoreSettings.isEmpty {
            restoreSettingsMap[token] = restoreSettings
        }

        let existingTokens = enabledTokens.filter { tokens.contains($0) }

        let newTokens = tokens.filter { !existingTokens.contains($0) }
        let removedTokens = existingTokens.filter { !tokens.contains($0) }

        for token in newTokens {
            enabledTokens.insert(token)
        }

        for token in removedTokens {
            enabledTokens.remove(token)
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

        for token in enabledTokens {
            if token.coin == coin {
                enabledTokens.remove(token)
            }
        }

        syncCanRestore()
        syncState()
    }

    private func handleCancelEnable(coin: Coin) {
        guard let token = tokens.first(where: { $0.coin == coin }) else {
            return
        }

        if !isEnabled(blockchain: token.blockchain) {
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
        let tokens = tokens.filter { $0.blockchain.uid == blockchainUid }

        guard let token = tokens.first else {
            return
        }

        enableCoinService.enable(fullCoin: FullCoin(coin: token.coin, tokens: tokens), accountType: accountType)
    }

    func disable(blockchainUid: String) {
        enabledTokens = enabledTokens.filter { $0.blockchain.uid != blockchainUid }

        syncState()
        syncCanRestore()
    }

    func configure(blockchainUid: String) {
        let tokens = tokens.filter { $0.blockchain.uid == blockchainUid }
        let enabledTokens = enabledTokens.filter { $0.blockchain.uid == blockchainUid }

        guard let token = tokens.first else {
            return
        }

        enableCoinService.configure(fullCoin: FullCoin(coin: token.coin, tokens: tokens), accountType: accountType, tokens: Array(enabledTokens))
    }

    func restore() {
        let account = accountFactory.account(type: accountType, origin: .restored, backedUp: isManualBackedUp, name: accountName)
        accountManager.save(account: account)

        for (token, settings) in restoreSettingsMap {
            enableCoinService.save(restoreSettings: settings, account: account, blockchainType: token.blockchainType)
        }

        guard !enabledTokens.isEmpty else {
            return
        }

        for blockchainType in Set(enabledTokens.map { $0.blockchainType }) {
            evmAccountRestoreStateManager.setRestored(account: account, blockchainType: blockchainType)
        }

        let wallets = enabledTokens.map { Wallet(token: $0, account: account) }
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

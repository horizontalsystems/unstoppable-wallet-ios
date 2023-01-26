import MarketKit

class ChooseBlockchainService {
    private let accountType: AccountType
    private let accountName: String
    private let accountFactory: AccountFactory
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let marketKit: MarketKit.Kit

    var blockchains = [Blockchain]()

    init(accountType: AccountType, accountName: String,
         accountFactory: AccountFactory, accountManager: AccountManager, walletManager: WalletManager,
         evmBlockchainManager: EvmBlockchainManager, marketKit: MarketKit.Kit) {
        self.accountType = accountType
        self.accountName = accountName
        self.accountFactory = accountFactory
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.evmBlockchainManager = evmBlockchainManager
        self.marketKit = marketKit

        blockchains = evmBlockchains()
    }

    private func evmBlockchains() -> [Blockchain] {
        let blockchainTypes: [BlockchainType] = [
            .ethereum,
            .binanceSmartChain,
            .polygon,
            .avalanche,
            .optimism,
            .arbitrumOne,
            .gnosis,
        ]

        guard let blockchains = try? marketKit.blockchains(uids: blockchainTypes.map { $0.uid }) else {
            return []
        }

        var orderedBlockchains = [Blockchain]()
        for type in blockchainTypes {
            guard let blockchain = blockchains.first(where: { $0.type == type }) else {
                continue
            }

            orderedBlockchains.append(blockchain)
        }

        return orderedBlockchains
    }

    private func enableWallets(account: Account, enabledBlockchainUids: [String]) {
        do {
            let enabledBlockchainItems = blockchains.filter { enabledBlockchainUids.contains($0.uid) }
            let tokenQueries = enabledBlockchainItems.map { TokenQuery(blockchainType: $0.type, tokenType: .native)}
            let tokens = try marketKit.tokens(queries: tokenQueries)

            let wallets = enabledBlockchainItems.compactMap { blockchain -> Wallet? in
                guard let token = tokens.first(where: { $0.blockchain.uid == blockchain.uid }) else {
                    return nil
                }

                return Wallet(token: token, account: account)
            }

            walletManager.save(wallets: wallets)
        } catch { }
    }

}

extension ChooseBlockchainService {

    func watch(enabledBlockchainUids: [String]) {
        let account = accountFactory.watchAccount(type: accountType, name: accountName)
        accountManager.save(account: account)
        enableWallets(account: account, enabledBlockchainUids: enabledBlockchainUids)
    }

}

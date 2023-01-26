import MarketKit

class ChooseBlockchainService {
    private let accountType: AccountType
    private let accountName: String
    private let accountFactory: AccountFactory
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let marketKit: MarketKit.Kit

    let items: [WatchModule.Item]

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

        items = evmBlockchainManager.allBlockchains
            .sorted(by: { $0.type.order < $1.type.order })
            .map { .blockchain(blockchain: $0) }
    }

    private func enableWallets(account: Account, enabledBlockchainUids: [String]) {
        do {
            var tokenQueries = [TokenQuery]()

            for item in items {
                guard case let .blockchain(blockchain) = item, enabledBlockchainUids.contains(blockchain.uid) else {
                    continue
                }

                tokenQueries.append(TokenQuery(blockchainType: blockchain.type, tokenType: .native))
            }

            let wallets = try marketKit.tokens(queries: tokenQueries).map { token in
                Wallet(token: token, account: account)
            }

            walletManager.save(wallets: wallets)
        } catch { }
    }

}

extension ChooseBlockchainService: IChooseWatchService {

    func watch(enabledUids: [String]) {
        let account = accountFactory.watchAccount(type: accountType, name: accountName)
        accountManager.save(account: account)
        enableWallets(account: account, enabledBlockchainUids: enabledUids)
    }

}

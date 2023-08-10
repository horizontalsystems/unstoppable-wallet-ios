import MarketKit

class ChooseCoinService {
    private let accountType: AccountType
    private let accountName: String
    private let accountFactory: AccountFactory
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let marketKit: MarketKit.Kit

    private(set) var items = [WatchModule.Item]()

    init(accountType: AccountType, accountName: String, accountFactory: AccountFactory, accountManager: AccountManager, walletManager: WalletManager, marketKit: MarketKit.Kit) {
        self.accountType = accountType
        self.accountName = accountName
        self.accountFactory = accountFactory
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.marketKit = marketKit

        items = btcItems()
    }

    private func btcItems() -> [WatchModule.Item] {
        guard case .hdExtendedKey(let key) = accountType, case .public = key else {
            return []
        }

        let blockchainTypes: [BlockchainType] = [.bitcoin, .bitcoinCash, .ecash, .litecoin, .dash]
        let tokenQueries = blockchainTypes.map { $0.nativeTokenQueries }.flatMap { $0 }

        guard let tokens = try? marketKit.tokens(queries: tokenQueries) else {
            return []
        }

        return tokens
                .filter { accountType.supports(token: $0) }
                .map { .coin(token: $0) }
    }

    private func enableWallets(account: Account, enabledTokensUids: [String]) {
        var wallets = [Wallet]()

        for item in items {
            guard case let .coin(token) = item, enabledTokensUids.contains(token.type.id) else {
                continue
            }

            wallets.append(Wallet(token: token, account: account))
        }

        walletManager.save(wallets: wallets)
    }

}

extension ChooseCoinService: IChooseWatchService {

    func watch(enabledUids: [String]) {
        let account = accountFactory.watchAccount(type: accountType, name: accountName)
        accountManager.save(account: account)
        enableWallets(account: account, enabledTokensUids: enabledUids)
    }

}

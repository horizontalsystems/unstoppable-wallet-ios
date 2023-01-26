import MarketKit

class ChooseCoinService {
    private let accountType: AccountType
    private let accountName: String
    private let accountFactory: AccountFactory
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let marketKit: MarketKit.Kit

    var items = [Item]()

    init(accountType: AccountType, accountName: String, accountFactory: AccountFactory, accountManager: AccountManager, walletManager: WalletManager, marketKit: MarketKit.Kit) {
        self.accountType = accountType
        self.accountName = accountName
        self.accountFactory = accountFactory
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.marketKit = marketKit

        items = btcTokens()
    }

    private func btcTokens() -> [Item] {
        guard case .hdExtendedKey(let key) = accountType, case .public = key else {
            return []
        }

        let blockchainTypes: [BlockchainType] = [.bitcoin, .bitcoinCash, .litecoin, .dash]
        let tokenQueries = blockchainTypes.map { TokenQuery(blockchainType: $0, tokenType: .native)}
        guard let tokens = try? marketKit.tokens(queries: tokenQueries) else {
            return []
        }

        var configuredTokens = [Item]()

        for (index, token) in tokens.enumerated() {
            guard token.blockchainType.supports(accountType: accountType) else {
                continue
            }

            switch token.blockchainType.coinSettingType {
                case .derivation:
                    let coinSettings: CoinSettings = [.derivation: key.info.purpose.mnemonicDerivation.rawValue]
                    configuredTokens.append(Item(uid: "\(index)", token: token, coinSettings: coinSettings))

                case .bitcoinCashCoinType:
                    BitcoinCashCoinType.allCases.forEach { coinType in
                        let coinSettings: CoinSettings = [.bitcoinCashCoinType: coinType.rawValue]
                        configuredTokens.append(Item(uid: "\(index)_\(coinType.rawValue)", token: token, coinSettings: coinSettings))
                    }

                default:
                    configuredTokens.append(Item(uid: "\(index)", token: token, coinSettings: [:]))
            }
        }

        return configuredTokens
    }

    private func enableWallets(account: Account, enabledTokensUids: [String]) {
        let enabledItems = items.filter { enabledTokensUids.contains($0.uid) }
        let wallets = enabledItems.map { item -> Wallet in
            let configuredToken = ConfiguredToken(token: item.token, coinSettings: item.coinSettings)
            return Wallet(configuredToken: configuredToken, account: account)
        }

        walletManager.save(wallets: wallets)
    }

}

extension ChooseCoinService {

    func watch(enabledTokensUids: [String]) {
        let account = accountFactory.watchAccount(type: accountType, name: accountName)
        accountManager.save(account: account)
        enableWallets(account: account, enabledTokensUids: enabledTokensUids)
    }

}

extension ChooseCoinService {

    struct Item {
        let uid: String
        let token: Token
        let coinSettings: CoinSettings
    }

}

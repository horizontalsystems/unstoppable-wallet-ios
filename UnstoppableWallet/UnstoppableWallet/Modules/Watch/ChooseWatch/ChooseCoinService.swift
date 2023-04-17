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
        let tokenQueries = blockchainTypes.map { TokenQuery(blockchainType: $0, tokenType: .native)}
        guard let tokens = try? marketKit.tokens(queries: tokenQueries) else {
            return []
        }

        var items = [WatchModule.Item]()

        for (index, token) in tokens.sorted(by: { $0.blockchainType.order < $1.blockchainType.order }).enumerated() {
            guard token.blockchainType.supports(accountType: accountType) else {
                continue
            }

            switch token.blockchainType.coinSettingType {
                case .derivation:
                    for purpose in key.purposes {
                        let coinSettings: CoinSettings = [.derivation: purpose.mnemonicDerivation.rawValue]
                        items.append(.coin(uid: "\(index)_\(purpose.mnemonicDerivation.rawValue)", token: token, coinSettings: coinSettings))
                    }

                case .bitcoinCashCoinType:
                    BitcoinCashCoinType.allCases.forEach { coinType in
                        let coinSettings: CoinSettings = [.bitcoinCashCoinType: coinType.rawValue]
                        items.append(.coin(uid: "\(index)_\(coinType.rawValue)", token: token, coinSettings: coinSettings))
                    }

                default:
                    items.append(.coin(uid: "\(index)", token: token, coinSettings: [:]))
            }
        }

        return items
    }

    private func enableWallets(account: Account, enabledTokensUids: [String]) {
        var wallets = [Wallet]()

        for item in items {
            guard case let .coin(uid, token, coinSettings) = item, enabledTokensUids.contains(uid) else {
                continue
            }

            let configuredToken = ConfiguredToken(token: token, coinSettings: coinSettings)
            wallets.append(Wallet(configuredToken: configuredToken, account: account))
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

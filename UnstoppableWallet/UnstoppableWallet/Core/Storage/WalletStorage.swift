import RxSwift
import MarketKit

class WalletStorage {
    private let marketKit: MarketKit.Kit
    private let storage: EnabledWalletStorage

    init(marketKit: MarketKit.Kit, storage: EnabledWalletStorage) {
        self.marketKit = marketKit
        self.storage = storage
    }

    private func enabledWallet(wallet: Wallet) -> EnabledWallet {
        EnabledWallet(
                tokenQueryId: wallet.token.tokenQuery.id,
                coinSettingsId: wallet.coinSettings.id,
                accountId: wallet.account.id,
                coinName: wallet.coin.name,
                coinCode: wallet.coin.code,
                tokenDecimals: wallet.token.decimals
        )
    }

}

extension WalletStorage {

    func wallets(account: Account) throws -> [Wallet] {
        let enabledWallets = try storage.enabledWallets(accountId: account.id)

        let queries = enabledWallets.compactMap { TokenQuery(id: $0.tokenQueryId) }
        let tokens = try marketKit.tokens(queries: queries)

        let blockchainUids = queries.map { $0.blockchainType.uid }
        let blockchains = try marketKit.blockchains(uids: blockchainUids)

        return enabledWallets.compactMap { enabledWallet in
            guard let tokenQuery = TokenQuery(id: enabledWallet.tokenQueryId) else {
                return nil
            }

            if let token = tokens.first(where: { $0.tokenQuery == tokenQuery }) {
                let coinSettings = CoinSettings(id: enabledWallet.coinSettingsId)
                let configuredToken = ConfiguredToken(token: token, coinSettings: coinSettings)
                return Wallet(configuredToken: configuredToken, account: account)
            }

            if let coinName = enabledWallet.coinName, let coinCode = enabledWallet.coinCode, let tokenDecimals = enabledWallet.tokenDecimals,
               let blockchain = blockchains.first(where: { $0.uid == tokenQuery.blockchainType.uid }) {
                let coinSettings = CoinSettings(id: enabledWallet.coinSettingsId)
                let coinUid = tokenQuery.customCoinUid

                let token = Token(
                        coin: Coin(uid: coinUid, name: coinName, code: coinCode),
                        blockchain: blockchain,
                        type: tokenQuery.tokenType,
                        decimals: tokenDecimals
                )

                let configuredToken = ConfiguredToken(token: token, coinSettings: coinSettings)
                return Wallet(configuredToken: configuredToken, account: account)
            }

            return nil
        }
    }

    func handle(newWallets: [Wallet], deletedWallets: [Wallet]) {
        let newEnabledWallets = newWallets.map { enabledWallet(wallet: $0) }
        let deletedEnabledWallets = deletedWallets.map { enabledWallet(wallet: $0) }
        try? storage.handle(newEnabledWallets: newEnabledWallets, deletedEnabledWallets: deletedEnabledWallets)
    }

    func handle(newEnabledWallets: [EnabledWallet]) {
        try? storage.handle(newEnabledWallets: newEnabledWallets, deletedEnabledWallets: [])
    }

    func clearWallets() {
        try? storage.clear()
    }

}

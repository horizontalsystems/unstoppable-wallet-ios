import MarketKit

enum RestoreHelper {
    static func supportedTokens(accountType: AccountType) -> [Token] {
        let tokenQueries = BlockchainType.supported.map(\.nativeTokenQueries).flatMap { $0 }
        let allTokens = (try? Core.shared.marketKit.tokens(queries: tokenQueries)) ?? []
        return allTokens.filter { accountType.supports(token: $0) }
    }

    static func restoreSingleBlockchain(accountName: String, accountType: AccountType, token: Token, backedUp: Bool = true, fileBackedUp: Bool = false) {
        let account = Core.shared.accountFactory.account(
            type: accountType,
            origin: .restored,
            backedUp: backedUp,
            fileBackedUp: fileBackedUp,
            name: accountName
        )
        Core.shared.accountManager.save(account: account)
        Core.shared.restoreStateManager.setShouldRestore(account: account, blockchainType: token.blockchainType)
        Core.shared.walletManager.save(wallets: [Wallet(token: token, account: account)])
    }
}

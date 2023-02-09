import MarketKit

extension FullCoin {

    func eligibleTokens(accountType: AccountType) -> [Token] {
        tokens
                .filter { $0.isSupported }
                .filter { $0.blockchainType.supports(accountType: accountType) }
    }

}

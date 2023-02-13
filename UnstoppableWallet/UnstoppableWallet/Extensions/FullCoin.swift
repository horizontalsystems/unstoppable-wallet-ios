import MarketKit

extension FullCoin {

    // todo: remove this method
    func eligibleTokens(accountType: AccountType) -> [Token] {
        tokens
                .filter { $0.isSupported }
                .filter { $0.blockchainType.supports(accountType: accountType) }
    }

}

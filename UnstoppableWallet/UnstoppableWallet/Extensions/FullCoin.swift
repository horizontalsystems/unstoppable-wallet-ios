import MarketKit

extension FullCoin {

    func eligibleTokens(accountType: AccountType) -> [Token] {
        tokens
                .filter { $0.isSupported }
                .filter { $0.blockchainType.supports(accountType: accountType) }
    }

}

extension Array where Element == FullCoin {

    mutating func sort(filter: String, isEnabled: (Coin) -> Bool) {
        sort { lhsFullCoin, rhsFullCoin in
            let lhsEnabled = isEnabled(lhsFullCoin.coin)
            let rhsEnabled = isEnabled(rhsFullCoin.coin)

            if lhsEnabled != rhsEnabled {
                return lhsEnabled
            }

            if !filter.isEmpty {
                let filter = filter.lowercased()

                let lhsExactCode = lhsFullCoin.coin.code.lowercased() == filter
                let rhsExactCode = rhsFullCoin.coin.code.lowercased() == filter

                if lhsExactCode != rhsExactCode {
                    return lhsExactCode
                }

                let lhsStartsWithCode = lhsFullCoin.coin.code.lowercased().starts(with: filter)
                let rhsStartsWithCode = rhsFullCoin.coin.code.lowercased().starts(with: filter)

                if lhsStartsWithCode != rhsStartsWithCode {
                    return lhsStartsWithCode
                }

                let lhsStartsWithName = lhsFullCoin.coin.name.lowercased().starts(with: filter)
                let rhsStartsWithName = rhsFullCoin.coin.name.lowercased().starts(with: filter)

                if lhsStartsWithName != rhsStartsWithName {
                    return lhsStartsWithName
                }
            }

            let lhsMarketCapRank = lhsFullCoin.coin.marketCapRank ?? Int.max
            let rhsMarketCapRank = rhsFullCoin.coin.marketCapRank ?? Int.max

            if lhsMarketCapRank != rhsMarketCapRank {
                return lhsMarketCapRank < rhsMarketCapRank
            }

            return lhsFullCoin.coin.name.lowercased() < rhsFullCoin.coin.name.lowercased()
        }
    }

}

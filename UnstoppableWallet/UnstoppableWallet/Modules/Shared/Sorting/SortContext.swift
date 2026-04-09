import Foundation
import MarketKit

class SortContext {
    var filter: String = ""
}

class EnabledSortContext: SortContext {
    var enabledTokens: Set<Token> = []
}

class TokenSortContext: EnabledSortContext {
    var referenceToken: Token?
    var balances: [Token: Decimal] = [:]
    var fiatBalances: [Token: Decimal] = [:]

    override init() {
        super.init()
    }

    convenience init(balances: [Token: Decimal], coinPrices: [String: Decimal]) {
        self.init()
        self.balances = balances
        fiatBalances = balances.reduce(into: [:]) { result, pair in
            if let price = coinPrices[pair.key.coin.uid] {
                result[pair.key] = pair.value * price
            }
        }
    }

    convenience init(balances: [Token: Decimal], fiatBalances: [Token: Decimal]) {
        self.init()
        self.balances = balances
        self.fiatBalances = fiatBalances
    }
}

class FullCoinSortContext: EnabledSortContext {
    var accountType: AccountType?
    var fullCoinFiatValues: [String: Decimal] = [:]

    override init() {
        super.init()
    }

    convenience init(coins: [FullCoin], balances: [Token: Decimal], coinPrices: [String: Decimal], accountType: AccountType? = nil) {
        self.init()
        self.accountType = accountType
        fullCoinFiatValues = coins.reduce(into: [:]) { result, fullCoin in

            // calculate sum of all supported tokens
            let total = fullCoin.tokens
                .filter { accountType?.supports(token: $0) ?? true }
                .reduce(Decimal(0)) { sum, token in
                    sum + (balances[token] ?? 0) * (coinPrices[token.coin.uid] ?? 0)
                }
            result[fullCoin.coin.uid] = total
        }
    }
    
    convenience init(fullCoinFiatValues: [String: Decimal], accountType: AccountType? = nil) {
        self.init()
        self.fullCoinFiatValues = fullCoinFiatValues
        self.accountType = accountType
    }
}

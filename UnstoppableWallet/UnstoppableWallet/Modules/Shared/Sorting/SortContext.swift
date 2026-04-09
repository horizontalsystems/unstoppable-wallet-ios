import Foundation
import MarketKit

class SortContext {
    var filter: String = ""
}

class EnabledSortContext: SortContext {
    var enabledTokens: Set<Token> = []

    // Keyed by a stable string identifier whose meaning depends on the concrete subclass:
    // - TokenSortContext uses token.tokenQuery.id (per-token concrete fiat value).
    // - FullCoinSortContext uses coin.uid (fiat value aggregated across all supported tokens).
    //
    // Entry presence also doubles as a "price is known" marker: both subclass inits only add
    // an entry when a coin price was available at build time, which .hasPriceFirst relies on.
    var fiatValues: [String: Decimal] = [:]
}

class TokenSortContext: EnabledSortContext {
    var referenceToken: Token?
    var balances: [Token: Decimal] = [:]

    override init() {
        super.init()
    }

    convenience init(balances: [Token: Decimal], coinPrices: [String: Decimal]) {
        self.init()
        self.balances = balances
        fiatValues = balances.reduce(into: [:]) { result, pair in
            if let price = coinPrices[pair.key.coin.uid] {
                result[pair.key.tokenQuery.id] = pair.value * price
            }
        }
    }

    // Callers passing this init must ensure fiatBalances contains entries only for tokens
    // whose price was known, so that fiatValues presence correctly reflects "has price".
    convenience init(balances: [Token: Decimal], fiatBalances: [Token: Decimal]) {
        self.init()
        self.balances = balances
        fiatValues = fiatBalances.reduce(into: [:]) { result, pair in
            result[pair.key.tokenQuery.id] = pair.value
        }
    }
}

class FullCoinSortContext: EnabledSortContext {
    var accountType: AccountType?

    override init() {
        super.init()
    }

    convenience init(coins: [FullCoin], balances: [Token: Decimal], coinPrices: [String: Decimal], accountType: AccountType? = nil) {
        self.init()
        self.accountType = accountType
        fiatValues = coins.reduce(into: [:]) { result, fullCoin in
            // Skip coins without a known price so that fiatValues presence correctly
            // reflects "has price" for .hasPriceFirst.
            guard coinPrices[fullCoin.coin.uid] != nil else { return }

            // Sum of balance * price across all supported tokens of this coin.
            let total = fullCoin.tokens
                .filter { accountType?.supports(token: $0) ?? true }
                .reduce(Decimal(0)) { sum, token in
                    sum + (balances[token] ?? 0) * (coinPrices[token.coin.uid] ?? 0)
                }
            result[fullCoin.coin.uid] = total
        }
    }

    // Callers passing this init must ensure fullCoinFiatValues contains entries only for coins
    // whose price was known, so that fiatValues presence correctly reflects "has price".
    convenience init(fullCoinFiatValues: [String: Decimal], accountType: AccountType? = nil) {
        self.init()
        fiatValues = fullCoinFiatValues
        self.accountType = accountType
    }
}

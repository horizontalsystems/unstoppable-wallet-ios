import Foundation
import MarketKit

enum MultiSwapDefaultPairResolver {
    static func resolve(_ input: Input) -> (tokenIn: Token?, tokenOut: Token?) {
        if let token = input.explicitToken {
            return (token, input.autoResolveTokenOut ? destination(for: token, input: input) : nil)
        }

        guard input.hasWallets, !input.items.isEmpty else {
            return (input.bitcoin, input.monero)
        }

        let context = TokenSortContext(
            balances: input.items.reduce(into: [:]) { $0[$1.token] = max(0, $1.balance) },
            coinPrices: input.items.reduce(into: [:]) { result, item in
                if let price = item.price, price > 0 {
                    result[item.token.coin.uid] = price
                }
            }
        )

        let funded = input.items.filter { $0.balance > 0 }

        guard !funded.isEmpty else {
            let tokens = input.items.map(\.token).sorted(by: SortCriterion.swapDefaultTopWallet, context: context)
            guard let source = tokens.first else {
                return (input.bitcoin, input.monero)
            }

            return (source, destination(for: source, input: input))
        }

        let priced = funded.filter { ($0.price ?? 0) > 0 }

        guard let source = priced.map(\.token).sorted(by: SortCriterion.swapDefaultSource, context: context).first else {
            return (input.bitcoin, input.monero)
        }

        return (source, destination(for: source, input: input))
    }

    private static func destination(for source: Token, input: Input) -> Token? {
        input.popularTokens(source).first ?? (source.blockchainType == .bitcoin ? input.monero : input.bitcoin)
    }
}

extension MultiSwapDefaultPairResolver {
    struct Item {
        let token: Token
        let balance: Decimal
        let price: Decimal?
    }

    struct Input {
        let explicitToken: Token?
        let autoResolveTokenOut: Bool
        let hasWallets: Bool
        let items: [Item]
        let popularTokens: (Token?) -> [Token]
        let bitcoin: Token?
        let monero: Token?
    }
}

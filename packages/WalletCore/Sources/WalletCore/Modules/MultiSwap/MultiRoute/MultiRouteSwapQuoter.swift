import Foundation
import MarketKit

// Finds the best way to divide a large swap: every provider is quoted for 1/N of the amount and the
// best N quotes become the routes, one per provider. Runs off the main thread and touches no UI state.
enum MultiRouteSwapQuoter {
    // nil when no split with at least `MultiRouteSwapConfig.minParts` usable routes exists,
    // when the task is cancelled, or when the split gives no more than the single route
    static func plan(
        providers: [IMultiSwapProvider],
        tokenIn: Token,
        tokenOut: Token,
        amountIn: Decimal,
        singleQuote: MultiSwapViewModel.Quote,
        parts: Int
    ) async -> MultiRouteSwapPlan? {
        guard parts >= MultiRouteSwapConfig.minParts else {
            return nil
        }

        print("SPLIT ROUTES: single quote \(singleQuote.provider.id): \(singleQuote.quote.expectedBuyAmount) \(tokenOut.coin.code)")

        for count in stride(from: parts, through: MultiRouteSwapConfig.minParts, by: -1) {
            guard !Task.isCancelled else {
                return nil
            }

            let amounts = MultiRouteSwapConfig.splitAmounts(total: amountIn, parts: count, decimals: tokenIn.decimals)

            guard let part = amounts.first, amounts.allSatisfy({ $0 > 0 }) else {
                return nil
            }

            // the single route's output scaled to one part, with headroom for a genuinely better route
            let maxPartAmountOut = singleQuote.quote.expectedBuyAmount / Decimal(count) * MultiRouteSwapConfig.maxPartGainFactor

            let quotes = await usableQuotes(providers: providers, tokenIn: tokenIn, tokenOut: tokenOut, amountIn: part, maxAmountOut: maxPartAmountOut)

            guard !Task.isCancelled else {
                return nil
            }

            guard quotes.count >= count else {
                print("SPLIT ROUTES: \(count) parts: only \(quotes.count) usable quotes")
                continue
            }

            let routes = zip(quotes.prefix(count), amounts).map { quote, amount in
                MultiRouteSwapPlan.Route(provider: quote.provider, amountIn: amount, quote: quote.quote)
            }

            let plan = MultiRouteSwapPlan(singleQuote: singleQuote, routes: routes)

            for route in routes {
                print("SPLIT ROUTES: \(count) parts: route \(route.provider.id): \(route.quote.expectedBuyAmount) \(tokenOut.coin.code)")
            }
            print("SPLIT ROUTES: \(count) parts: sum \(plan.totalAmountOut) vs single \(singleQuote.quote.expectedBuyAmount) \(tokenOut.coin.code), gain \(plan.gain)")

            return plan.gain > 0 ? plan : nil
        }

        return nil
    }

    // Successful quotes that need no pre-swap step (such as an approve for another spender) and promise
    // no more than `maxAmountOut`, best first. A provider that fails or times out is simply not a candidate.
    private static func usableQuotes(providers: [IMultiSwapProvider], tokenIn: Token, tokenOut: Token, amountIn: Decimal, maxAmountOut: Decimal) async -> [MultiSwapViewModel.Quote] {
        let quotes: [MultiSwapViewModel.Quote] = await withTaskGroup(of: MultiSwapViewModel.Quote?.self) { group in
            for provider in providers {
                group.addTask {
                    do {
                        let quote = try await MultiSwapViewModel.quoteWithTimeout(
                            provider: provider,
                            tokenIn: tokenIn,
                            tokenOut: tokenOut,
                            amountIn: amountIn
                        )

                        return MultiSwapViewModel.Quote(provider: provider, quote: quote)
                    } catch {
                        return nil
                    }
                }
            }

            var collected = [MultiSwapViewModel.Quote]()

            for await quote in group {
                if let quote {
                    collected.append(quote)
                }
            }

            return collected
        }

        return quotes
            .filter { usable(quote: $0.quote) && $0.quote.expectedBuyAmount <= maxAmountOut }
            .sorted { $0.quote.expectedBuyAmount > $1.quote.expectedBuyAmount }
    }

    // A route is sent as is: it must not spend through an ERC-20 allowance, must need no pre-swap step
    // and must not be blocked by its own button state
    private static func usable(quote: MultiSwapQuote) -> Bool {
        guard !quote.approveRequired else {
            return false
        }

        guard let state = quote.customButtonState else {
            return true
        }

        return state.preSwapStep == nil && !state.disabled
    }
}

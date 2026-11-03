import Foundation
import MarketKit

/// Finds a 1-hop route for a pair that can't be swapped directly.
///
/// Pure matching over injected candidate tiers and an injected "is this token quotable" predicate (the
/// asset catalog's membership): the only `Core.shared` touch is the `make` factory.
final class SwapPathFinder {
    private let candidateProviders: [ISwapPathCandidateProvider]

    init(candidateProviders: [ISwapPathCandidateProvider]) {
        self.candidateProviders = candidateProviders
    }

    static func make(marketKit: IMarketKit = Core.shared.marketKit) -> SwapPathFinder {
        SwapPathFinder(candidateProviders: [
            NativeSwapPathCandidateProvider(marketKit: marketKit),
            CoinListSwapPathCandidateProvider(marketKit: marketKit),
        ])
    }

    /// `isKnown` is catalog membership: an intermediate token no venue lists cannot carry either leg.
    func find(tokenIn: Token, tokenOut: Token, isKnown: (Token) -> Bool) -> SwapPath? {
        let endpointIds: Set<String> = [tokenIn.tokenQuery.id, tokenOut.tokenQuery.id]
        var triedIds = Set<String>()

        // Declared tier order IS the ranking the product asked for — first hit wins, no scoring.
        for candidateProvider in candidateProviders {
            for candidate in candidateProvider.candidates(tokenIn: tokenIn, tokenOut: tokenOut) {
                let id = candidate.tokenQuery.id

                guard !endpointIds.contains(id), triedIds.insert(id).inserted, isKnown(candidate) else {
                    continue
                }

                return SwapPath(tokenIn: tokenIn, intermediateToken: candidate, tokenOut: tokenOut)
            }
        }

        return nil
    }
}

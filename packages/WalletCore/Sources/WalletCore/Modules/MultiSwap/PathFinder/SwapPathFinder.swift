import Foundation
import MarketKit

/// Finds a 1-hop route for a pair that can't be swapped directly.
///
/// Pure matching over injected candidate tiers: the only I/O is whatever the candidate providers do,
/// and the only `Core.shared` touch is the `make` factory.
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

    func find(tokenIn: Token, tokenOut: Token, providers: [IMultiSwapProvider], suspensions: SwapSuspensionIndex) -> SwapPath? {
        // Same gate as MultiSwapViewModel.syncValidProviders: a leg we would refuse to quote must
        // not count, or we would advertise a route through a provider the backend switched off.
        func usable(provider: IMultiSwapProvider, from: Token, to: Token) -> Bool {
            guard !suspensions.isSuspended(providerId: provider.id, tokenIn: from, tokenOut: to) else {
                return false
            }

            return provider.supports(tokenIn: from, tokenOut: to)
        }

        let endpointIds: Set<String> = [tokenIn.tokenQuery.id, tokenOut.tokenQuery.id]
        var triedIds = Set<String>()

        // Declared tier order IS the ranking the product asked for — first hit wins, no scoring.
        for candidateProvider in candidateProviders {
            for candidate in candidateProvider.candidates(tokenIn: tokenIn, tokenOut: tokenOut) {
                let id = candidate.tokenQuery.id

                guard !endpointIds.contains(id), triedIds.insert(id).inserted else {
                    continue
                }

                // No point asking about the second leg with no way in.
                guard providers.contains(where: { usable(provider: $0, from: tokenIn, to: candidate) }) else {
                    continue
                }

                guard providers.contains(where: { usable(provider: $0, from: candidate, to: tokenOut) }) else {
                    continue
                }

                return SwapPath(tokenIn: tokenIn, intermediateToken: candidate, tokenOut: tokenOut)
            }
        }

        return nil
    }
}

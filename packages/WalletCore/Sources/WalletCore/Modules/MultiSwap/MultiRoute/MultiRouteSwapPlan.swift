import Foundation

// A large swap divided into parts, one route per provider, compared against the single route
public struct MultiRouteSwapPlan {
    public struct Route {
        let provider: IMultiSwapProvider
        let amountIn: Decimal
        let quote: MultiSwapQuote
    }

    // the current quote at the moment Next was tapped
    let singleQuote: MultiSwapViewModel.Quote
    // 2...4 routes, sorted by expected buy amount, best first
    let routes: [Route]
    // Which routes of this plan were already broadcast. Created with the plan and shared by every copy
    // of it, so a confirmation handler rebuilt from the same plan never sends a route again.
    let sentRoutes = MultiRouteSentRoutesHolder()

    var routeCount: Int {
        routes.count
    }

    var totalAmountOut: Decimal {
        routes.reduce(0) { $0 + $1.quote.expectedBuyAmount }
    }

    // Approximate: every route was quoted for the rounded-down part, so the last route's quote does not
    // include its remainder (at most a few units of the last decimal); the confirmation re-previews exact amounts
    var gain: Decimal {
        totalAmountOut - singleQuote.quote.expectedBuyAmount
    }

    var worstProviderType: SwapProviderType {
        routes.map(\.provider.type).min { $0.rank < $1.rank } ?? singleQuote.provider.type
    }

    var longestEstimatedTime: TimeInterval? {
        routes.compactMap(\.quote.estimatedTime).max()
    }

    var preciseEstimateTime: Bool {
        routes.allSatisfy(\.provider.preciseEstimateTime)
    }

    var requireTerms: Bool {
        routes.contains { $0.provider.requireTerms }
    }
}

// The routes of one plan already broadcast, and the nonce the last of them was sent with.
// A reference type on purpose, like `SwapExternalRecipientHolder`: the handler is rebuilt from a
// `SendData` value whenever the confirmation is reopened, and must see what earlier handlers sent.
public final class MultiRouteSentRoutesHolder: @unchecked Sendable {
    private let lock = NSLock()
    private var _indices = Set<Int>()
    private var _lastUsedNonce: Int?

    init() {}

    // indices into the plan's `routes`
    var indices: Set<Int> {
        lock.withLock { _indices }
    }

    // the nonce pinned on the last route sent; nil when nothing was sent or the nonce was not pinned
    var lastUsedNonce: Int? {
        lock.withLock { _lastUsedNonce }
    }

    func markSent(index: Int, nonce: Int?) {
        lock.withLock {
            _indices.insert(index)

            if let nonce {
                _lastUsedNonce = max(_lastUsedNonce ?? nonce, nonce)
            }
        }
    }
}

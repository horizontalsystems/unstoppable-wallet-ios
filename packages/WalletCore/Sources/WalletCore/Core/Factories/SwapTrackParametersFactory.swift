import Foundation

// App-supplied enrichment of swap track requests: extra parameters the host app can derive from the
// swap (e.g. attributes of its own accounts the server cannot read off the transaction). Empty by
// default — an app that registers nothing sends requests exactly as before.
public protocol ISwapTrackParametersProvider {
    static func extraParameters(swap: Swap) -> [String: Any]
}

public enum SwapTrackParametersFactory {
    private static var providers: [ISwapTrackParametersProvider.Type] = []

    public static func register(_ provider: ISwapTrackParametersProvider.Type) {
        providers.append(provider)
    }

    static func extraParameters(swap: Swap) -> [String: Any] {
        providers.reduce(into: [:]) { result, provider in
            result.merge(provider.extraParameters(swap: swap)) { current, _ in current }
        }
    }

    // test seam: registry is global mutable state
    static func reset() {
        providers = []
    }
}

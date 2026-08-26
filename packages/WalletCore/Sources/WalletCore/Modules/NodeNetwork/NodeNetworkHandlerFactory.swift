import MarketKit

public enum NodeNetworkHandlerFactory {
    private static var providers: [NodeNetworkHandlerProvider.Type] = []

    public static func register(_ provider: NodeNetworkHandlerProvider.Type) {
        providers.append(provider)
    }

    public static func prepend(_ provider: NodeNetworkHandlerProvider.Type) {
        providers.insert(provider, at: 0)
    }

    static func handlers(blockchain: Blockchain) -> NodeNetworkHandlers? {
        for provider in providers {
            if let handlers = provider.instance(blockchain: blockchain) {
                return handlers
            }
        }

        return nil
    }
}

public extension NodeNetworkHandlerFactory {
    static let unstoppableHandlers: [NodeNetworkHandlerProvider.Type] = [
        ZcashNodeNetworkHandler.self,
    ]
}

import MarketKit

public enum SwapBroadcasterFactory {
    private static var types: [ISwapBroadcasterType.Type] = []

    public static func register(_ types: [ISwapBroadcasterType.Type]) {
        Self.types.append(contentsOf: types)
    }

    public static func prepend(_ type: ISwapBroadcasterType.Type) {
        types.insert(type, at: 0)
    }

    public static func broadcaster(blockchainType: BlockchainType, account: Account) throws -> ISwapBroadcaster {
        for type in types {
            if let broadcaster = type.make(blockchainType: blockchainType, account: account) {
                return broadcaster
            }
        }

        throw SwapBroadcasterError.noBroadcaster
    }

    // test seam: registry is global mutable state
    static func reset() {
        types = []
    }
}

public extension SwapBroadcasterFactory {
    static let unstoppableBroadcasters: [ISwapBroadcasterType.Type] = [
        EvmSwapBroadcaster.self,
        UtxoSwapBroadcaster.self,
        ZcashSwapBroadcaster.self,
        TronSwapBroadcaster.self,
        TonSwapBroadcaster.self,
        StellarSwapBroadcaster.self,
        SolanaSwapBroadcaster.self,
        MoneroSwapBroadcaster.self,
        ZanoSwapBroadcaster.self,
    ]
}

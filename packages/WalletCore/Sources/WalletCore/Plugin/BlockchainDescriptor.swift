import MarketKit

/// Static facts about one blockchain a plugin supports. Later phases add fields with defaulted init parameters.
public struct BlockchainDescriptor {
    public let type: BlockchainType
    public let family: String

    public init(type: BlockchainType, family: String) {
        self.type = type
        self.family = family
    }
}

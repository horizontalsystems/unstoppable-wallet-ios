import MarketKit

extension BlockchainType {
    /// The registered plugin's facts about this blockchain; nil for a chain no plugin describes,
    /// and before `Core.instance` is set. Reads the immutable registry: safe on any thread.
    var descriptor: BlockchainDescriptor? {
        Core.instance?.registry.descriptor(for: self)
    }
}

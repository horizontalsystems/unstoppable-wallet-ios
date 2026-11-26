import MarketKit

/// Supplies the address parsers of the plugin's blockchains.
protocol AddressCapability: BlockchainPlugin {
    /// Raw-address parsers, then name-service parsers when `withEns` is true. Called on any thread.
    func addressParserItems(blockchainType: BlockchainType, withEns: Bool) -> [IAddressParserItem]
}

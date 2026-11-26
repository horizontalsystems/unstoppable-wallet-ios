import MarketKit

/// Supplies the custom-token services of the plugin's blockchains.
protocol TokenCapability: BlockchainPlugin {
    /// nil when custom tokens cannot be added on this blockchain. Called on the main thread.
    func addTokenService(blockchain: Blockchain) -> IAddTokenBlockchainService?
}

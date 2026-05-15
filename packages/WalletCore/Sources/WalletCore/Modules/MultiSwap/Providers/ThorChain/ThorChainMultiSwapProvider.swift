class ThorChainMultiSwapProvider: BaseThorChainMultiSwapProvider {
    static let id = "THORCHAIN"
    static let name = "THORChain"

    override var baseUrl: String {
        "https://gateway.liquify.com/chain/thorchain_api/thorchain"
    }

    override var id: String { Self.id }
    override var name: String { Self.name }
    override var type: SwapProviderType { .excellent }
    override var icon: String { "swap_provider_thorchain" }

    override var affiliate: String? {
        AppConfig.thorchainAffiliate
    }

    override var affiliateBps: Int? {
        AppConfig.thorchainAffiliateBps
    }

    override var streamingInterval: Int { 0 }
}

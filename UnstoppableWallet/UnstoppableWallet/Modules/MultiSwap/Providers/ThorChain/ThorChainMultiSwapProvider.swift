class ThorChainMultiSwapProvider: BaseThorChainMultiSwapProvider {
    static let id = "THORCHAIN"

    override var baseUrl: String {
        "https://thornode.ninerealms.com/thorchain"
    }

    override var id: String { Self.id }
    override var name: String { "THORChain" }
    override var type: SwapProviderType { .auto }
    override var icon: String { "swap_provider_thorchain" }

    override var affiliate: String? {
        AppConfig.thorchainAffiliate
    }

    override var affiliateBps: Int? {
        AppConfig.thorchainAffiliateBps
    }
}

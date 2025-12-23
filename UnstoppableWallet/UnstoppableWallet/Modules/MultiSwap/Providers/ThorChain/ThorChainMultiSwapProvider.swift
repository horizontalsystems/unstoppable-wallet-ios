class ThorChainMultiSwapProvider: BaseThorChainMultiSwapProvider {
    override var baseUrl: String {
        "https://thornode.ninerealms.com/thorchain"
    }

    override var id: String { "thorchain" }
    override var name: String { "THORChain" }
    override var description: String { "DEX" }
    override var icon: String { "swap_provider_thorchain" }

    override var affiliate: String? {
        AppConfig.thorchainAffiliate
    }

    override var affiliateBps: Int? {
        AppConfig.thorchainAffiliateBps
    }
}

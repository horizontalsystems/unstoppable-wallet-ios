class ThorChainMultiSwapProvider: BaseThorChainMultiSwapProvider {
    override var baseUrl: String {
        "https://thornode.ninerealms.com/thorchain"
    }

    override var id: String {
        "thorchain"
    }

    override var name: String {
        "THORChain"
    }

    override var icon: String {
        "thorchain_32"
    }

    override var affiliate: String? {
        AppConfig.thorchainAffiliate
    }

    override var affiliateBps: Int? {
        AppConfig.thorchainAffiliateBps
    }
}

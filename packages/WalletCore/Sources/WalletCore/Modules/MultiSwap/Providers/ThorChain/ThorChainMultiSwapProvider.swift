public class ThorChainMultiSwapProvider: BaseThorChainMultiSwapProvider {
    public static let id = "THORCHAIN"
    static let name = "THORChain"

    override var baseUrl: String {
        "https://gateway.liquify.com/chain/thorchain_api/thorchain"
    }

    override var securedAssetsSupported: Bool { true }

    override public var id: String { Self.id }
    override public var name: String { Self.name }
    override public var type: SwapProviderType { .excellent }
    override public var icon: String { "swap_provider_thorchain" }

    override var affiliate: String? {
        AppConfig.thorchainAffiliate
    }

    override var affiliateBps: Int? {
        AppConfig.thorchainAffiliateBps
    }

    override var streamingInterval: Int { 0 }
}

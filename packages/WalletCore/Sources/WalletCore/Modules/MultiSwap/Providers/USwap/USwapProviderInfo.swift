public struct USwapProviderInfo: Equatable {
    public let id: String
    public let name: String
    public let icon: String
    public let preciseEstimateTime: Bool
    public let requireTerms: Bool
    // Routes through a confidential rail. The private send flow offers a provider only when both the server
    // (ConfidentialProviderRegistry) and this flag mark it confidential; the swap screen lists it like any other.
    public let confidential: Bool
    // Takes a unified ZEC address as the refund target. Not published by /v3/providers, so declared here:
    // transfer venues validate a ZEC refund as transparent (QuickEx and StealthEX reject `u1`), Maya refunds to
    // the memo's address (Sapling receiver), 1Click to an Orchard one.
    public let acceptsUnifiedZcashRefund: Bool

    public init(id: String, name: String, icon: String, preciseEstimateTime: Bool = true, requireTerms: Bool, confidential: Bool = false, acceptsUnifiedZcashRefund: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.preciseEstimateTime = preciseEstimateTime
        self.requireTerms = requireTerms
        self.confidential = confidential
        self.acceptsUnifiedZcashRefund = acceptsUnifiedZcashRefund
    }
}

public extension USwapProviderInfo {
    static let near = USwapProviderInfo(
        id: "NEAR",
        name: "Near",
        icon: "swap_provider_near",
        requireTerms: true,
        acceptsUnifiedZcashRefund: true
    )

    // Quoted on the ordinary swap screen like the others and also used by the private send flow,
    // which resolves it through ConfidentialProviderRegistry.
    static let nearConfidential = USwapProviderInfo(
        id: "NEAR_CONFIDENTIAL",
        name: "Near Confidential",
        icon: "swap_provider_near",
        requireTerms: true,
        confidential: true
    )

    static let quickEx = USwapProviderInfo(
        id: "QUICKEX",
        name: "QuickEx",
        icon: "swap_provider_quickex",
        preciseEstimateTime: false,
        requireTerms: true
    )

    static let letsExchange = USwapProviderInfo(
        id: "LETSEXCHANGE",
        name: "LetsExchange",
        icon: "swap_provider_letsexchange",
        preciseEstimateTime: false,
        requireTerms: true
    )

    static let stealthex = USwapProviderInfo(
        id: "STEALTHEX",
        name: "StealthEX",
        icon: "swap_provider_stealthex",
        preciseEstimateTime: false,
        requireTerms: true
    )

    static let swapuz = USwapProviderInfo(
        id: "SWAPUZ",
        name: "Swapuz",
        icon: "swap_provider_swapuz",
        preciseEstimateTime: false,
        requireTerms: true
    )

    // Swapuz's split orders under their own provider name: `splitSwaps: true`, `quotes: false`, so it is
    // offered on the Private tab only and never sent to /v3/rate. Not confidential: the server reports
    // `privacy: "split"` for it, and ConfidentialProviderRegistry drops it because this flag is false, so it
    // is never offered for Private Send.
    static let swapuzSplit = USwapProviderInfo(
        id: "SWAPUZ_SPLIT",
        name: "Swapuz",
        icon: "swap_provider_swapuz",
        preciseEstimateTime: false,
        requireTerms: true
    )

    static let exolix = USwapProviderInfo(
        id: "EXOLIX",
        name: "Exolix",
        icon: "swap_provider_exolix",
        preciseEstimateTime: false,
        requireTerms: true
    )

    static let cce = USwapProviderInfo(
        id: "CCE",
        name: "CCE Cash",
        icon: "swap_provider_cce",
        preciseEstimateTime: false,
        requireTerms: true
    )

    static let barter = USwapProviderInfo(
        id: "BARTER",
        name: "Barter",
        icon: "swap_provider_barter",
        requireTerms: true
    )

    static let soroswap = USwapProviderInfo(
        id: "SOROSWAP",
        name: "Soroswap",
        icon: "stellar_stellar_32",
        requireTerms: true
    )

    static let aquarius = USwapProviderInfo(
        id: "AQUARIUS",
        name: "Aquarius",
        icon: "stellar_stellar_32",
        requireTerms: true
    )

    static let stellarDex = USwapProviderInfo(
        id: "STELLAR_DEX",
        name: "Stellar DEX",
        icon: "stellar_stellar_32",
        requireTerms: true
    )

    // History only: records made through the former single Stellar card. Never quoted.
    static let stellarBroker = USwapProviderInfo(
        id: "STELLARBROKER",
        name: "StellarBroker",
        icon: "stellar_stellar_32",
        requireTerms: true
    )

    static let pegasus = USwapProviderInfo(
        id: "PEGASUS",
        name: "PegasusSwap",
        icon: "swap_provider_pegasus",
        preciseEstimateTime: false,
        requireTerms: true
    )

    static let circle = USwapProviderInfo(
        id: "CIRCLE",
        name: "Circle CCTP",
        icon: "swap_provider_circle",
        requireTerms: true
    )

    static let jupiter = USwapProviderInfo(
        id: "JUPITER",
        name: "Jupiter",
        icon: "swap_provider_jupiter",
        requireTerms: true
    )

    static let lifi = USwapProviderInfo(
        id: "LIFI",
        name: "LI.FI",
        icon: "swap_provider_lifi",
        requireTerms: true
    )

    static let oneInch = USwapProviderInfo(
        id: "ONEINCH",
        name: "1inch",
        icon: "swap_provider_1inch",
        requireTerms: true
    )

    static let uniswap = USwapProviderInfo(
        id: "UNISWAP",
        name: "Uniswap",
        icon: "swap_provider_uniswap",
        requireTerms: true
    )

    static let thorChain = USwapProviderInfo(
        id: "THORCHAIN",
        name: "THORChain",
        icon: "swap_provider_thorchain",
        requireTerms: true
    )

    static let maya = USwapProviderInfo(
        id: "MAYACHAIN",
        name: "Maya Protocol",
        icon: "swap_provider_maya",
        requireTerms: true,
        acceptsUnifiedZcashRefund: true
    )

    static let axelarIts = USwapProviderInfo(
        id: "AXELAR_ITS",
        name: "Axelar ITS",
        icon: "swap_provider_axelar",
        requireTerms: true
    )

    static let lizex = USwapProviderInfo(
        id: "LIZEX",
        name: "Lizex",
        icon: "swap_provider_lizex",
        preciseEstimateTime: false,
        requireTerms: true
    )

    static let bitania = USwapProviderInfo(
        id: "BITANIA",
        name: "Bitania",
        icon: "swap_provider_bitania",
        preciseEstimateTime: false,
        requireTerms: true
    )

    static let xswap = USwapProviderInfo(
        id: "XSWAP",
        name: "XSwap",
        icon: "swap_provider_xswap",
        preciseEstimateTime: false,
        requireTerms: true
    )
}

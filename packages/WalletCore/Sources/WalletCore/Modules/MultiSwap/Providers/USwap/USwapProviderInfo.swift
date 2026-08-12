public struct USwapProviderInfo: Equatable {
    public let id: String
    public let name: String
    public let icon: String
    public let type: SwapProviderType
    public let preciseEstimateTime: Bool
    public let requireTerms: Bool
    // Routes through a confidential rail. Such providers are excluded from the ordinary swap
    // fan-out; availability itself is decided by ConfidentialProviderRegistry, not by this flag.
    public let confidential: Bool

    public init(id: String, name: String, icon: String, type: SwapProviderType, preciseEstimateTime: Bool = true, requireTerms: Bool, confidential: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.type = type
        self.preciseEstimateTime = preciseEstimateTime
        self.requireTerms = requireTerms
        self.confidential = confidential
    }
}

public extension USwapProviderInfo {
    static let near = USwapProviderInfo(
        id: "NEAR",
        name: "Near",
        icon: "swap_provider_near",
        type: .fair,
        requireTerms: true
    )

    // Registered so SwapProviderFactory.provider(id:) resolves the provider for tracking and
    // history rendering. It is never offered on the ordinary swap screen.
    static let nearConfidential = USwapProviderInfo(
        id: "NEAR_CONFIDENTIAL",
        name: "Near Confidential",
        icon: "swap_provider_near",
        type: .fair,
        requireTerms: true,
        confidential: true
    )

    static let quickEx = USwapProviderInfo(
        id: "QUICKEX",
        name: "QuickEx",
        icon: "swap_provider_quickex",
        type: .good,
        preciseEstimateTime: false,
        requireTerms: true
    )

    static let letsExchange = USwapProviderInfo(
        id: "LETSEXCHANGE",
        name: "LetsExchange",
        icon: "swap_provider_letsexchange",
        type: .good,
        preciseEstimateTime: false,
        requireTerms: true
    )

    static let stealthex = USwapProviderInfo(
        id: "STEALTHEX",
        name: "StealthEX",
        icon: "swap_provider_stealthex",
        type: .fair,
        preciseEstimateTime: false,
        requireTerms: true
    )

    static let swapuz = USwapProviderInfo(
        id: "SWAPUZ",
        name: "Swapuz",
        icon: "swap_provider_swapuz",
        type: .good,
        preciseEstimateTime: false,
        requireTerms: true
    )

    static let exolix = USwapProviderInfo(
        id: "EXOLIX",
        name: "Exolix",
        icon: "swap_provider_exolix",
        type: .good,
        preciseEstimateTime: false,
        requireTerms: true
    )

    static let cce = USwapProviderInfo(
        id: "CCE",
        name: "CCE Cash",
        icon: "swap_provider_cce",
        type: .good,
        preciseEstimateTime: false,
        requireTerms: true
    )

    static let barter = USwapProviderInfo(
        id: "BARTER",
        name: "Barter",
        icon: "swap_provider_barter",
        type: .excellent,
        requireTerms: true
    )

    static let pegasus = USwapProviderInfo(
        id: "PEGASUS",
        name: "PegasusSwap",
        icon: "swap_provider_pegasus",
        type: .good,
        preciseEstimateTime: false,
        requireTerms: true
    )

    static let circle = USwapProviderInfo(
        id: "CIRCLE",
        name: "Circle CCTP",
        icon: "swap_provider_circle",
        type: .excellent,
        requireTerms: true
    )

    static let jupiter = USwapProviderInfo(
        id: "JUPITER",
        name: "Jupiter",
        icon: "swap_provider_jupiter",
        type: .excellent,
        requireTerms: true
    )

    static let lifi = USwapProviderInfo(
        id: "LIFI",
        name: "LI.FI",
        icon: "swap_provider_lifi",
        type: .excellent,
        requireTerms: true
    )

    static let axelarIts = USwapProviderInfo(
        id: "AXELAR_ITS",
        name: "Axelar ITS",
        icon: "swap_provider_axelar",
        type: .excellent,
        requireTerms: true
    )

    static let lizex = USwapProviderInfo(
        id: "LIZEX",
        name: "Lizex",
        icon: "swap_provider_lizex",
        type: .good,
        preciseEstimateTime: false,
        requireTerms: true
    )

    static let bitania = USwapProviderInfo(
        id: "BITANIA",
        name: "Bitania",
        icon: "swap_provider_bitania",
        type: .good,
        preciseEstimateTime: false,
        requireTerms: true
    )
}

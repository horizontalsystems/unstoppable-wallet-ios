public struct USwapProviderInfo: Equatable {
    public let id: String
    public let name: String
    public let icon: String
    public let type: SwapProviderType
    public let requireTerms: Bool

    public init(id: String, name: String, icon: String, type: SwapProviderType, requireTerms: Bool) {
        self.id = id
        self.name = name
        self.icon = icon
        self.type = type
        self.requireTerms = requireTerms
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

    static let quickEx = USwapProviderInfo(
        id: "QUICKEX",
        name: "QuickEx",
        icon: "swap_provider_quickex",
        type: .good,
        requireTerms: true
    )

    static let letsExchange = USwapProviderInfo(
        id: "LETSEXCHANGE",
        name: "LetsExchange",
        icon: "swap_provider_letsexchange",
        type: .good,
        requireTerms: true
    )

    static let stealthex = USwapProviderInfo(
        id: "STEALTHEX",
        name: "StealthEX",
        icon: "swap_provider_stealthex",
        type: .fair,
        requireTerms: true
    )

    static let swapuz = USwapProviderInfo(
        id: "SWAPUZ",
        name: "Swapuz",
        icon: "swap_provider_swapuz",
        type: .good,
        requireTerms: true
    )

    static let exolix = USwapProviderInfo(
        id: "EXOLIX",
        name: "Exolix",
        icon: "swap_provider_exolix",
        type: .good,
        requireTerms: true
    )

    static let cce = USwapProviderInfo(
        id: "CCE",
        name: "CCE Cash",
        icon: "swap_provider_cce",
        type: .good,
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
}

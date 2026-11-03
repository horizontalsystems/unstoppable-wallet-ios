import Foundation

/// A backend provider id as the app knows it through the synced `GET /v3/providers` rows: the venue a
/// route is served by. `isKnown` is false for an id the last sync did not list (a humanized name and the
/// route's own `amlPolicy` stand in until the next sync).
public struct SwapVenue: Equatable {
    public let id: String
    public let name: String
    /// The AML policy published by the backend; nil when it has not rated the provider.
    public let type: SwapProviderType?
    /// `none` | `basic` | ...; any value other than `none` is confidential.
    public let privacy: String
    public let executionType: String?
    public let isKnown: Bool

    public init(id: String, name: String, type: SwapProviderType?, privacy: String, executionType: String?, isKnown: Bool) {
        self.id = id
        self.name = name
        self.type = type
        self.privacy = privacy
        self.executionType = executionType
        self.isKnown = isKnown
    }

    public static let noPrivacy = "none"

    public var isConfidential: Bool {
        privacy != Self.noPrivacy
    }

    /// The route's `amlPolicy` wins over the synced row's when present: it is the policy of this quote.
    func overriding(amlPolicy: String?) -> SwapVenue {
        guard let amlPolicy, let routeType = SwapProviderType(rawValue: amlPolicy.lowercased()) else {
            return self
        }

        return SwapVenue(id: id, name: name, type: routeType, privacy: privacy, executionType: executionType, isKnown: isKnown)
    }

    /// `PANCAKESWAP_API` -> `Pancakeswap Api`: the fallback for an id the provider list has no name for.
    static func humanized(id: String) -> String {
        id.split(separator: "_")
            .map { word in word.prefix(1).uppercased() + word.dropFirst().lowercased() }
            .joined(separator: " ")
    }

    static func unknown(id: String) -> SwapVenue {
        SwapVenue(id: id, name: humanized(id: id), type: nil, privacy: noPrivacy, executionType: nil, isKnown: false)
    }
}

import Foundation
import MarketKit

/// How a blockchain's send form and swap deposits treat a memo.
public struct MemoPolicy {
    public let type: MemoType
    /// The send form's memo limit in UTF-8 bytes; nil when the form offers no memo.
    public let maxBytes: Int?
    public let ridesOpReturn: Bool

    public static let none = MemoPolicy(type: .none, maxBytes: nil, ridesOpReturn: false)

    public init(type: MemoType, maxBytes: Int?, ridesOpReturn: Bool) {
        self.type = type
        self.maxBytes = maxBytes
        self.ridesOpReturn = ridesOpReturn
    }
}

/// Static facts about one blockchain a plugin supports. Pure data: `BlockchainType` and `Token` members read
/// these first and fall back to their legacy tables for a chain no plugin describes.
public struct BlockchainDescriptor {
    public let type: BlockchainType
    public let family: String
    /// Position in blockchain lists; lower first.
    let order: Int
    let nativeTokenQueries: [TokenQuery]
    let defaultTokenQuery: TokenQuery
    let restoreSettingTypes: [RestoreSettingType]
    let memo: MemoPolicy
    let uriScheme: String?
    let feePriceScale: FeePriceScale
    let resendable: Bool
    let blockTime: TimeInterval?
    let description: String
    let sendToSelfAllowed: Bool

    public init(type: BlockchainType, family: String) {
        self.init(type: type, family: family, order: .max)
    }

    init(
        type: BlockchainType,
        family: String,
        order: Int = .max,
        nativeTokenQueries: [TokenQuery]? = nil,
        defaultTokenQuery: TokenQuery? = nil,
        restoreSettingTypes: [RestoreSettingType] = [],
        memo: MemoPolicy = .none,
        uriScheme: String? = nil,
        feePriceScale: FeePriceScale = .gwei,
        resendable: Bool = true,
        blockTime: TimeInterval? = nil,
        description: String = "",
        sendToSelfAllowed: Bool = true
    ) {
        let nativeTokenQuery = TokenQuery(blockchainType: type, tokenType: .native)

        self.type = type
        self.family = family
        self.order = order
        self.nativeTokenQueries = nativeTokenQueries ?? [nativeTokenQuery]
        self.defaultTokenQuery = defaultTokenQuery ?? nativeTokenQuery
        self.restoreSettingTypes = restoreSettingTypes
        self.memo = memo
        self.uriScheme = uriScheme
        self.feePriceScale = feePriceScale
        self.resendable = resendable
        self.blockTime = blockTime
        self.description = description
        self.sendToSelfAllowed = sendToSelfAllowed
    }
}

import Foundation
import MarketKit

public protocol ISwapExecutable {}

public protocol IPrepared {}

public struct DirectPrepared: IPrepared {
    let executable: ISwapExecutable
}

public struct BroadcastResult {
    public let txHash: String?
    public let trackingHandle: String?

    public init(txHash: String?, trackingHandle: String?) {
        self.txHash = txHash
        self.trackingHandle = trackingHandle
    }
}

public protocol ISwapBroadcaster {
    // how often the confirm screen may re-run prepare; nil = handler default
    var expirationDuration: Int? { get }
    func prepare(_ executable: ISwapExecutable) async throws -> IPrepared
    func submit(_ prepared: IPrepared) async throws -> BroadcastResult
}

public extension ISwapBroadcaster {
    var expirationDuration: Int? { nil }
}

public protocol ISwapBroadcasterType {
    static func make(blockchainType: BlockchainType, account: Account) -> ISwapBroadcaster?
}

// A self-rendering prepared owns the payment view wholesale: fee, canSend, fee rows AND validity
// cautions (the quote's transactionError cautions describe the native path it does not use).
// CONTRACT: since the quote's cautions are fully replaced, a conformer MUST re-validate the swap
// input itself (canSend and/or cautions) — e.g. a balance/reserve check in the fee token.
public protocol IPreparedDisplay: IPrepared {
    var canSend: Bool { get }
    var extraRateCoins: [Coin] { get }
    func feeSections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection]
    func cautions(baseToken: Token) -> [CautionNew]
}

public extension IPreparedDisplay {
    func cautions(baseToken _: Token) -> [CautionNew] {
        []
    }
}

// extensible: downstream apps add errors via `extension SwapBroadcasterError { static var ... }`
public struct SwapBroadcasterError: Error, Equatable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static var noBroadcaster: Self { .init(rawValue: "noBroadcaster") }
    public static var dataMismatch: Self { .init(rawValue: "dataMismatch") }
}

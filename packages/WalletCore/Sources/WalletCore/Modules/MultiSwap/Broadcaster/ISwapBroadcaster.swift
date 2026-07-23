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

/// A `submit()` failure where value may ALREADY have moved on-chain — e.g. an interactive
/// broker session (StellarBroker) that signed and submitted transactions before failing.
/// Carries the last known tx hash so the send handler can persist a trackable swap record
/// (instead of a ghost swap the server record waits on forever) before surfacing the error.
public protocol IPartialExecutionError: Error {
    var partialTxHash: String? { get }
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

// extensible: downstream apps add errors via `extension SwapBroadcasterError { static var ... }`
public struct SwapBroadcasterError: Error, Equatable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static var noBroadcaster: Self { .init(rawValue: "noBroadcaster") }
    public static var dataMismatch: Self { .init(rawValue: "dataMismatch") }
}

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
    func prepare(_ executable: ISwapExecutable) async throws -> IPrepared
    func submit(_ prepared: IPrepared) async throws -> BroadcastResult
}

public protocol ISwapBroadcasterType {
    static func make(blockchainType: BlockchainType, account: Account) -> ISwapBroadcaster?
}

public protocol IPreparedDisplay: IPrepared {
    var canSend: Bool { get }
    var extraRateCoins: [Coin] { get }
    func feeSections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection]
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

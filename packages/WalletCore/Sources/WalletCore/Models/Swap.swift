import Foundation
import GRDB
import MarketKit
import SwiftUI

public struct Swap: Hashable {
    public let uid: String
    public let txHash: String?
    // opaque mechanism handle (set by the broadcaster) used by resolve() to attach
    // the on-chain txHash later; nil for directly-broadcast swaps
    public let trackingHandle: String?
    let accountId: String
    public let providerId: String
    public var status: Status
    public let tokenIn: Token
    public let tokenOut: Token
    public let amountIn: Decimal
    public var amountOut: Decimal
    public let recipient: String?
    let toAddress: String
    let depositAddress: String?
    public let providerSwapId: String?
    let sourceAddress: String?
    let refundAddress: String?
    public let estimatedTime: TimeInterval?
    public let date: Date
    public var fromAsset: String?
    public var toAsset: String?
    public var legs: [Leg]?
    var pauseReason: String?

    var isPending: Bool {
        Self.pendingStatuses.contains(status)
    }

    static var pendingStatuses: [Status] {
        [.notStarted, .pending, .swapping]
    }

    public init(uid: String, txHash: String?, trackingHandle: String?, accountId: String, providerId: String, status: Status, tokenIn: Token, tokenOut: Token, amountIn: Decimal, amountOut: Decimal, recipient: String?, toAddress: String, depositAddress: String?, providerSwapId: String?, sourceAddress: String?, refundAddress: String?, estimatedTime: TimeInterval? = nil, date: Date, fromAsset: String? = nil, toAsset: String? = nil, legs: [Leg]? = nil, pauseReason: String? = nil) {
        self.uid = uid
        self.txHash = txHash
        self.trackingHandle = trackingHandle
        self.accountId = accountId
        self.providerId = providerId
        self.status = status
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.amountIn = amountIn
        self.amountOut = amountOut
        self.recipient = recipient
        self.toAddress = toAddress
        self.depositAddress = depositAddress
        self.providerSwapId = providerSwapId
        self.sourceAddress = sourceAddress
        self.refundAddress = refundAddress
        self.estimatedTime = estimatedTime
        self.date = date
        self.fromAsset = fromAsset
        self.toAsset = toAsset
        self.legs = legs
        self.pauseReason = pauseReason
    }

    public enum Status: String {
        case notStarted = "not_started"
        case pending
        case swapping
        case completed
        case refunded
        case unknown
        case failed
        case actionRequired = "action_required"

        var title: String {
            "swap_info.status.\(rawValue)".localized
        }

        public var isExpected: Bool {
            switch self {
            case .notStarted, .pending, .swapping, .completed: true
            default: false
            }
        }

        @ViewBuilder var view: some View {
            switch self {
            case .completed: ThemeImage("done_e_filled", size: 20, colorStyle: .green)
            case .failed, .actionRequired: ThemeImage("warning_filled", size: 20, colorStyle: .red)
            case .refunded: ThemeImage("arrow_return", size: 20, colorStyle: .secondary)
            default: ProgressView(value: 0.55)
                .progressViewStyle(DeterminiteSpinnerStyle())
                .frame(width: 20, height: 20)
                .spinning()
            }
        }
    }
}

public extension Swap {
    struct Leg: Hashable {
        public let status: Status
        public let type: String
        public let chainId: String
        public let txHash: String
        public let fromAsset: String
        public let toAsset: String
    }
}

struct SwapRecord: Codable {
    let uid: String
    let txHash: String?
    let trackingHandle: String?
    let accountId: String
    let providerId: String
    let status: String
    let tokenQueryIdIn: String
    let tokenQueryIdOut: String
    let amountIn: String
    let amountOut: String
    let recipient: String?
    let toAddress: String
    let depositAddress: String?
    let providerSwapId: String?
    let sourceAddress: String?
    let refundAddress: String?
    let estimatedTime: TimeInterval?
    let date: Date
    let fromAsset: String?
    let toAsset: String?
    let legs: [Leg]?
    let pauseReason: String?
}

extension SwapRecord {
    struct Leg: Codable {
        let status: String
        let type: String
        let chainId: String
        let txHash: String
        let fromAsset: String
        let toAsset: String
    }
}

extension SwapRecord: FetchableRecord, PersistableRecord {
    static var databaseTableName: String {
        "SwapRecord"
    }

    enum Columns {
        static let uid = Column(CodingKeys.uid)
        static let txHash = Column(CodingKeys.txHash)
        static let trackingHandle = Column(CodingKeys.trackingHandle)
        static let accountId = Column(CodingKeys.accountId)
        static let providerId = Column(CodingKeys.providerId)
        static let status = Column(CodingKeys.status)
        static let tokenQueryIdIn = Column(CodingKeys.tokenQueryIdIn)
        static let tokenQueryIdOut = Column(CodingKeys.tokenQueryIdOut)
        static let amountIn = Column(CodingKeys.amountIn)
        static let amountOut = Column(CodingKeys.amountOut)
        static let recipient = Column(CodingKeys.recipient)
        static let toAddress = Column(CodingKeys.toAddress)
        static let depositAddress = Column(CodingKeys.depositAddress)
        static let providerSwapId = Column(CodingKeys.providerSwapId)
        static let sourceAddress = Column(CodingKeys.sourceAddress)
        static let refundAddress = Column(CodingKeys.refundAddress)
        static let estimatedTime = Column(CodingKeys.estimatedTime)
        static let date = Column(CodingKeys.date)
        static let fromAsset = Column(CodingKeys.fromAsset)
        static let toAsset = Column(CodingKeys.toAsset)
        static let legs = Column(CodingKeys.legs)
        static let pauseReason = Column(CodingKeys.pauseReason)
    }
}

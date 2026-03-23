import Foundation
import GRDB
import MarketKit
import SwiftUI

struct Swap: Hashable {
    let uid: String
    let txHash: String?
    let accountId: String
    let providerId: String
    var status: Status
    let tokenIn: Token
    let tokenOut: Token
    let amountIn: Decimal
    var amountOut: Decimal
    let recipient: String?
    let toAddress: String
    let depositAddress: String?
    let providerSwapId: String?
    let date: Date
    var fromAsset: String?
    var toAsset: String?
    var legs: [Leg]?

    var isPending: Bool {
        Self.pendingStatuses.contains(status)
    }

    static var pendingStatuses: [Status] {
        [.notStarted, .pending, .swapping, .unknown]
    }

    enum Status: String {
        case notStarted = "not_started"
        case pending
        case swapping
        case completed
        case refunded
        case unknown
        case failed

        var title: String {
            "swap_info.status.\(rawValue)".localized
        }

        @ViewBuilder var view: some View {
            switch self {
            case .completed: ThemeImage("done_e_filled", size: 20, colorStyle: .green)
            case .failed: ThemeImage("warning_filled", size: 20, colorStyle: .red)
            case .refunded: ThemeImage("arrow_return", size: 20, colorStyle: .secondary)
            default: ProgressView(value: 0.55)
                .progressViewStyle(DeterminiteSpinnerStyle())
                .frame(width: 20, height: 20)
                .spinning()
            }
        }
    }
}

extension Swap {
    struct Leg: Hashable {
        let status: Status
        let type: String
        let chainId: String
        let txHash: String
        let fromAsset: String
        let toAsset: String
    }
}

struct SwapRecord: Codable {
    let uid: String
    let txHash: String?
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
    let date: Date
    let fromAsset: String?
    let toAsset: String?
    let legs: [Leg]?
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
        static let date = Column(CodingKeys.date)
        static let fromAsset = Column(CodingKeys.fromAsset)
        static let toAsset = Column(CodingKeys.toAsset)
        static let legs = Column(CodingKeys.legs)
    }
}

import Foundation
import MarketKit

// What the `.crossPay` SendData case carries: deposit address and ZEC amount don't exist until commit.
public struct CrossPayRequest {
    public let tokenIn: Token // the funding token (ZEC)
    public let tokenOut: Token // what the recipient receives
    public let recipient: String // the REAL recipient on tokenOut's chain, never a deposit address
    public let amount: Decimal // exact output — the amount of tokenOut the recipient receives

    public init(tokenIn: Token, tokenOut: Token, recipient: String, amount: Decimal) {
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.recipient = recipient
        self.amount = amount
    }
}

// The committed order, produced by /v2/swap inside the handler on the confirmation screen.
public struct CrossPayOrder {
    public let request: CrossPayRequest
    public let depositAmount: Decimal // execution.amount in tokenIn — EXACTLY what to transfer
    public let minSellAmount: Decimal? // below it the deposit is refunded and no swap happens
    public let amountOut: Decimal // what the recipient gets; == request.amount by the exactness check
    public let providerId: String // tracking only — never shown in the UI
    public let depositAddress: String
    public let attachment: USwapMultiSwapApi.Attachment?
    public let providerSwapId: String
    public let refundAddress: String // non-optional: the buffer refund lands here
    public let estimatedTime: TimeInterval?
    public let committedAt: Date

    public init(
        request: CrossPayRequest,
        depositAmount: Decimal,
        minSellAmount: Decimal?,
        amountOut: Decimal,
        providerId: String,
        depositAddress: String,
        attachment: USwapMultiSwapApi.Attachment?,
        providerSwapId: String,
        refundAddress: String,
        estimatedTime: TimeInterval?,
        committedAt: Date
    ) {
        self.request = request
        self.depositAmount = depositAmount
        self.minSellAmount = minSellAmount
        self.amountOut = amountOut
        self.providerId = providerId
        self.depositAddress = depositAddress
        self.attachment = attachment
        self.providerSwapId = providerSwapId
        self.refundAddress = refundAddress
        self.estimatedTime = estimatedTime
        self.committedAt = committedAt
    }

    // No cross-asset fee figure: subtracting a tokenOut quantity from a tokenIn one is meaningless.
    public var refundableBuffer: Decimal? {
        minSellAmount.map { max(0, depositAmount - $0) }
    }
}

// Raw server text never leaves the service. Min/max figures are in the DESTINATION token — the
// amount field the user can act on.
public enum CrossPayError: Error {
    case tokenUnsupported
    case belowMinimum(amount: Decimal, token: Token)
    case aboveMaximum(amount: Decimal, token: Token)
    case noRoute
    case providerSuspended
    case networkError(Error)
    case commitFailed
}

extension CrossPayError: UserFacingError {
    public var errorDescription: String? {
        switch self {
        case .tokenUnsupported:
            return "cross_pay.error.token_unsupported".localized
        case let .belowMinimum(amount, token):
            return "cross_pay.error.below_minimum %@".localized(Self.formatted(amount: amount, token: token))
        case let .aboveMaximum(amount, token):
            return "cross_pay.error.above_maximum %@".localized(Self.formatted(amount: amount, token: token))
        case .noRoute:
            return "cross_pay.error.no_route".localized
        case .providerSuspended:
            return "cross_pay.error.provider_suspended".localized
        case .networkError:
            // Not surfaced: transport errors name hosts and provider ids.
            return "cross_pay.error.network".localized
        case .commitFailed:
            // One message for the whole commit-side taxonomy — internals would not help the user act.
            return "cross_pay.error.commit_failed".localized
        }
    }

    public var failureReason: String? {
        "cross_pay.unavailable".localized
    }

    private static func formatted(amount: Decimal, token: Token) -> String {
        let figure = ValueFormatter.instance.formatFull(value: amount, decimalCount: token.decimals) ?? "\(amount)"
        return "\(figure) \(token.coin.code)"
    }
}

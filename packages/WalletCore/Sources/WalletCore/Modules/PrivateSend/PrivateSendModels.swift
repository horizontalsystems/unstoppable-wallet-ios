import Foundation
import MarketKit

// The intent, known at pre-send time. This is what the `.privateSend` SendData case carries: neither
// the deposit address nor the amount to transfer exists until the order is committed.
public struct PrivateSendRequest {
    public let token: Token // sent == received token
    public let recipient: String // the REAL recipient, never a deposit address
    public let amount: Decimal // exact output — the amount the recipient receives

    public init(token: Token, recipient: String, amount: Decimal) {
        self.token = token
        self.recipient = recipient
        self.amount = amount
    }
}

// The committed order, produced by /v2/swap inside the handler on the confirmation screen.
public struct PrivateSendOrder {
    public let request: PrivateSendRequest
    public let depositAmount: Decimal // execution.amount — EXACTLY what to transfer
    public let minSellAmount: Decimal? // below it the deposit is refunded and no swap happens
    public let amountOut: Decimal // what the recipient gets
    public let minAmountOut: Decimal? // == amountOut in exact-output mode
    public let providerId: String // tracking only — never shown in the UI
    public let depositAddress: String
    public let attachment: USwapMultiSwapApi.Attachment?
    public let providerSwapId: String
    public let refundAddress: String // non-optional: the buffer refund lands here
    public let estimatedTime: TimeInterval?
    public let committedAt: Date

    public init(
        request: PrivateSendRequest,
        depositAmount: Decimal,
        minSellAmount: Decimal?,
        amountOut: Decimal,
        minAmountOut: Decimal?,
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
        self.minAmountOut = minAmountOut
        self.providerId = providerId
        self.depositAddress = depositAddress
        self.attachment = attachment
        self.providerSwapId = providerSwapId
        self.refundAddress = refundAddress
        self.estimatedTime = estimatedTime
        self.committedAt = committedAt
    }

    // The route's cost, NOT `depositAmount - amountOut`: the gap up to `depositAmount` is a
    // refundable deposit ceiling, not a price. With `minSellAmount` unknown this over-states rather
    // than under-states, and PrivateSendData raises `buffer_unknown` alongside it.
    public var privateFee: Decimal {
        max(0, (minSellAmount ?? depositAmount) - amountOut)
    }

    public var refundableBuffer: Decimal? {
        minSellAmount.map { max(0, depositAmount - $0) }
    }
}

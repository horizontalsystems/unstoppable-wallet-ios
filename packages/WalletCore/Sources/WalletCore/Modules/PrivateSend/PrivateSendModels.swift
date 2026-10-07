import Foundation
import MarketKit

// The intent, known at pre-send time. This is what the `.privateSend` SendData case carries: neither
// the deposit address nor the amount to transfer exists until the order is committed.
public struct PrivateSendRequest {
    public let token: Token // sent == received token
    public let recipient: String // the REAL recipient, never a deposit address
    public let amount: Decimal // exact output — the amount the recipient receives
    // An immutable copy of the user's send settings, taken on the main thread when the request is
    // built, so they apply to the deposit transfer without the handler ever reading the live,
    // UI-owned pre-send handler. Nil falls back to default settings.
    public let depositSettings: PreSendSettingsSnapshot?

    public init(token: Token, recipient: String, amount: Decimal, depositSettings: PreSendSettingsSnapshot? = nil) {
        self.token = token
        self.recipient = recipient
        self.amount = amount
        self.depositSettings = depositSettings
    }
}

// A previewed route (/v3/preview), produced inside the handler for the confirmation screen. No order
// exists yet: the token is handed to /v3/commit when the user slides. `stubDepositAddress` is a
// ready-to-receive account on the sell chain the inner send is estimated against — never a
// destination to send to.
public struct PrivateSendPreview {
    public let request: PrivateSendRequest
    public let previewToken: String
    public let providerId: String // tracking only — never shown in the UI
    public let depositAmount: Decimal // the preview's sellAmount — the ceiling the slide authorizes
    public let minSellAmount: Decimal? // below it the deposit is refunded and no swap happens
    public let amountOut: Decimal // what the recipient gets
    public let minAmountOut: Decimal? // == amountOut in exact-output mode
    public let stubDepositAddress: String
    public let refundAddress: String // non-optional: the buffer refund lands here
    public let estimatedTime: TimeInterval?
    public let previewedAt: Date

    public init(
        request: PrivateSendRequest,
        previewToken: String,
        providerId: String,
        depositAmount: Decimal,
        minSellAmount: Decimal?,
        amountOut: Decimal,
        minAmountOut: Decimal?,
        stubDepositAddress: String,
        refundAddress: String,
        estimatedTime: TimeInterval?,
        previewedAt: Date
    ) {
        self.request = request
        self.previewToken = previewToken
        self.providerId = providerId
        self.depositAmount = depositAmount
        self.minSellAmount = minSellAmount
        self.amountOut = amountOut
        self.minAmountOut = minAmountOut
        self.stubDepositAddress = stubDepositAddress
        self.refundAddress = refundAddress
        self.estimatedTime = estimatedTime
        self.previewedAt = previewedAt
    }

    // The route's cost, NOT `depositAmount - amountOut`: the gap up to `depositAmount` is a
    // refundable deposit ceiling, not a price. With `minSellAmount` unknown this over-states rather
    // than under-states — an upper bound, never a lowball.
    public var privateFee: Decimal {
        max(0, (minSellAmount ?? depositAmount) - amountOut)
    }

    public var refundableBuffer: Decimal? {
        minSellAmount.map { max(0, depositAmount - $0) }
    }
}

// The committed order (/v3/commit on a preview), produced inside the handler when the user slides.
public struct PrivateSendOrder {
    public let request: PrivateSendRequest
    public let depositAmount: Decimal // the commit's amount — EXACTLY what to transfer, never above the preview's
    public let minSellAmount: Decimal? // below it the deposit is refunded and no swap happens
    public let amountOut: Decimal // what the recipient gets
    public let minAmountOut: Decimal? // == amountOut in exact-output mode
    public let providerId: String // tracking only — never shown in the UI
    public let depositAddress: String
    public let attachment: USwapMultiSwapApi.Attachment?
    public let providerSwapId: String
    public let refundAddress: String // non-optional: the buffer refund lands here
    public let estimatedTime: TimeInterval?

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
        estimatedTime: TimeInterval?
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
    }

    // Everything the commit does not restate is carried over from the preview the user confirmed.
    public init(
        preview: PrivateSendPreview,
        depositAmount: Decimal,
        amountOut: Decimal,
        minAmountOut: Decimal?,
        depositAddress: String,
        attachment: USwapMultiSwapApi.Attachment?,
        providerSwapId: String
    ) {
        self.init(
            request: preview.request,
            depositAmount: depositAmount,
            minSellAmount: preview.minSellAmount,
            amountOut: amountOut,
            minAmountOut: minAmountOut,
            providerId: preview.providerId,
            depositAddress: depositAddress,
            attachment: attachment,
            providerSwapId: providerSwapId,
            refundAddress: preview.refundAddress,
            estimatedTime: preview.estimatedTime
        )
    }
}

import Foundation
import MarketKit

// What the `.crossPay` SendData case carries: the funding amount is known at preview, the deposit
// address only after commit.
public struct CrossPayRequest {
    public let tokenIn: Token // the funding token (the wallet being sent from)
    public let tokenOut: Token // what the recipient receives
    public let recipient: String // the REAL recipient on tokenOut's chain, never a deposit address
    public let amount: Decimal // exact output — the amount of tokenOut the recipient receives
    // An immutable copy of the user's send settings, taken on the main thread when the request is
    // built, so they apply to the deposit transfer without the handler ever reading the live,
    // UI-owned pre-send handler. Nil falls back to default settings.
    public let depositSettings: PreSendSettingsSnapshot?

    public init(tokenIn: Token, tokenOut: Token, recipient: String, amount: Decimal, depositSettings: PreSendSettingsSnapshot? = nil) {
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.recipient = recipient
        self.amount = amount
        self.depositSettings = depositSettings
    }
}

// A previewed route (/v3/preview), produced inside the handler for the confirmation screen. No order
// exists yet: the token is handed to /v3/commit when the user slides. `stubDepositAddress` is a
// ready-to-receive account on the sell chain the inner send is estimated against — never a
// destination to send to.
public struct CrossPayPreview {
    public let request: CrossPayRequest
    public let previewToken: String
    public let depositAmount: Decimal // the preview's sellAmount in tokenIn — what the user confirms and what is transferred
    public let minSellAmount: Decimal? // below it the deposit is refunded and no swap happens
    public let amountOut: Decimal // what the recipient gets; == request.amount by the exactness check
    public let stubDepositAddress: String
    public let refundAddress: String // non-optional: the buffer refund lands here
    public let estimatedTime: TimeInterval?
    public let previewedAt: Date

    public init(
        request: CrossPayRequest,
        previewToken: String,
        depositAmount: Decimal,
        minSellAmount: Decimal?,
        amountOut: Decimal,
        stubDepositAddress: String,
        refundAddress: String,
        estimatedTime: TimeInterval?,
        previewedAt: Date
    ) {
        self.request = request
        self.previewToken = previewToken
        self.depositAmount = depositAmount
        self.minSellAmount = minSellAmount
        self.amountOut = amountOut
        self.stubDepositAddress = stubDepositAddress
        self.refundAddress = refundAddress
        self.estimatedTime = estimatedTime
        self.previewedAt = previewedAt
    }

    // No cross-asset fee figure: subtracting a tokenOut quantity from a tokenIn one is meaningless.
    public var refundableBuffer: Decimal? {
        minSellAmount.map { max(0, depositAmount - $0) }
    }
}

// The committed order (/v3/commit on a preview), produced inside the handler when the user slides.
public struct CrossPayOrder {
    public let request: CrossPayRequest
    public let depositAmount: Decimal // the PREVIEW's sellAmount in tokenIn — EXACTLY what to transfer
    public let minSellAmount: Decimal? // below it the deposit is refunded and no swap happens
    public let amountOut: Decimal // what the recipient gets
    public let providerId: String // tracking only — never shown in the UI
    public let depositAddress: String
    public let attachment: USwapMultiSwapApi.Attachment?
    public let providerSwapId: String
    public let refundAddress: String // non-optional: the buffer refund lands here
    public let estimatedTime: TimeInterval?

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
        estimatedTime: TimeInterval?
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
    }

    // Everything the commit does not restate is carried over from the preview the user confirmed.
    public init(
        preview: CrossPayPreview,
        depositAmount: Decimal,
        amountOut: Decimal,
        depositAddress: String,
        attachment: USwapMultiSwapApi.Attachment?,
        providerSwapId: String
    ) {
        self.init(
            request: preview.request,
            depositAmount: depositAmount,
            minSellAmount: preview.minSellAmount,
            amountOut: amountOut,
            providerId: CrossPayService.providerId,
            depositAddress: depositAddress,
            attachment: attachment,
            providerSwapId: providerSwapId,
            refundAddress: preview.refundAddress,
            estimatedTime: preview.estimatedTime
        )
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
    // /v3/commit refusals, by the server's discriminator. Toasted by the handler on a refused commit
    // (the screen re-previews). `previewExpired` is also thrown out of sendData(...) when two preview
    // passes in a row come back stale, in which case it is the confirmation screen's error view.
    case rateChanged
    case previewExpired
    case commitRejected
    // A second broadcast started while one was in flight (double-tap / overlapping send); never sent.
    case alreadySending
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
        case .rateChanged:
            return "swap.confirmation.commit.rate_changed".localized
        case .previewExpired:
            return "swap.confirmation.commit.refresh_required".localized
        case .commitRejected:
            return "swap.confirmation.commit.failed".localized
        case .alreadySending:
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

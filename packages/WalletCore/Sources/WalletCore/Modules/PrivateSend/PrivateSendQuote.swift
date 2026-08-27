import Foundation

public struct PrivateSendQuote {
    public let providerId: String // tracking only — never shown in the UI
    // The route's answer to the exact-output request: the amount to deposit, and the affordability
    // ceiling the user is asked to authorize.
    public let sellAmount: Decimal
    public let minSellAmount: Decimal?
    public let expectedBuyAmount: Decimal
    public let minBuyAmount: Decimal?
    public let estimatedTime: TimeInterval?
    public let quotedAt: Date

    public init(
        providerId: String,
        sellAmount: Decimal,
        minSellAmount: Decimal?,
        expectedBuyAmount: Decimal,
        minBuyAmount: Decimal?,
        estimatedTime: TimeInterval?,
        quotedAt: Date
    ) {
        self.providerId = providerId
        self.sellAmount = sellAmount
        self.minSellAmount = minSellAmount
        self.expectedBuyAmount = expectedBuyAmount
        self.minBuyAmount = minBuyAmount
        self.estimatedTime = estimatedTime
        self.quotedAt = quotedAt
    }

    public var privateFee: Decimal {
        max(0, (minSellAmount ?? sellAmount) - expectedBuyAmount)
    }

    public var refundableBuffer: Decimal? {
        minSellAmount.map { max(0, sellAmount - $0) }
    }
}

public enum PrivateSendUnavailableReason: Error {
    case belowMinimum(amount: Decimal)
    case aboveMaximum(amount: Decimal)
    case noRoute
    case exactOutputUnsupported
    case providerSuspended
    case networkError(Error)
    case tokenUnsupported
}

public enum PrivateSendError: Error {
    case notQuoted
    case missingUuid
    case unsupportedExecution
    case chainMismatch
    case missingDepositAmount
    case depositBelowMinimum
    case invalidAmountOut
    case missingRefundAddress
    case attachmentUnsupported
    case innerSendDataUnavailable
    case noInnerHandler
    case noBaseToken
    case alreadySending
    case invalidData
}

// Both error types are thrown out of PrivateSendHandler.sendData(transactionSettings:) and land in
// SendViewModel's generic `catch`. UserFacingError is what lets SendView.errorView show the authored
// reason instead of the bare "couldn't fetch data" placeholder — without it the whole taxonomy is
// invisible and every private_send.caution.* string is dead copy. Every case below returns a
// localized string built only from values we control; no server text is ever interpolated.
extension PrivateSendUnavailableReason: UserFacingError {
    public var errorDescription: String? {
        switch self {
        case let .belowMinimum(amount):
            // Named, not merely reported: the user only learns the floor on the confirmation screen
            // and has to go back and change the amount to act on it.
            return "private_send.caution.below_minimum %@".localized(Self.formatted(amount: amount))
        case let .aboveMaximum(amount):
            return "private_send.caution.above_maximum %@".localized(Self.formatted(amount: amount))
        case .noRoute:
            return "private_send.caution.no_route".localized
        case .exactOutputUnsupported:
            return "private_send.caution.exact_output_unsupported".localized
        case .providerSuspended:
            return "private_send.caution.provider_suspended".localized
        case .networkError:
            // The underlying transport error is deliberately not surfaced: it names hosts and
            // provider ids, and this is the one feature whose point is unlinkability.
            return "private_send.caution.network_error".localized
        case .tokenUnsupported:
            return "private_send.caution.token_unsupported".localized
        }
    }

    public var failureReason: String? {
        "private_send.unavailable".localized
    }

    // The reason carries a bare Decimal (no token context reaches it), so the amount is formatted
    // without a symbol. The screen it renders on is single-token, so the figure is unambiguous.
    private static func formatted(amount: Decimal) -> String {
        ValueFormatter.instance.formatFull(value: amount, decimalCount: 8) ?? "\(amount)"
    }
}

extension PrivateSendError: UserFacingError {
    public var errorDescription: String? {
        // One message for every case: each is a "we could not set this up" from the user's side,
        // and naming the internals would leak route detail without helping them act.
        "private_send.commit_failed".localized
    }

    public var failureReason: String? {
        "private_send.unavailable".localized
    }
}

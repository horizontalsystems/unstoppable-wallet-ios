import Foundation
import MarketKit

// `open`, not `final`: every veto below is identical on both platforms and is written once here,
// while `sections(...)` is the seam each app re-authors in its own SendField idiom.
open class PrivateSendData: ISendData {
    // A committed quote is only honoured for this long. Past it the screen dead-ends rather than
    // pretending to be current — the sellAmount ceiling is what the slide-to-send authorizes.
    public static let quoteLifetime: TimeInterval = 15

    public let order: PrivateSendOrder
    public let inner: ISendData
    // The handler that produced `inner`, carried here deliberately rather than read back off
    // PrivateSendHandler at send time: two overlapping sendData(...) calls each prepare their own
    // handler/data pair, and broadcasting through the wrong one would send a transaction built
    // against different TransactionSettings than the user confirmed. Never rendered.
    public let innerHandler: ISendHandler
    public let attachmentUnsupported: Bool

    public init(order: PrivateSendOrder, inner: ISendData, innerHandler: ISendHandler, attachmentUnsupported: Bool) {
        self.order = order
        self.inner = inner
        self.innerHandler = innerHandler
        self.attachmentUnsupported = attachmentUnsupported
    }

    public var feeData: FeeData? {
        inner.feeData
    }

    public var rateCoins: [Coin] {
        inner.rateCoins + [order.request.token.coin]
    }

    public var amountAdjusted: Bool {
        inner.amountAdjusted
    }

    public var canSend: Bool {
        inner.canSend && !inner.amountAdjusted && !attachmentUnsupported
    }

    public var customSendButtonTitle: String? {
        inner.customSendButtonTitle
    }

    // Overridden by a platform subclass that can recognise its own inner data type. The base returns
    // false because WalletCore's inners report a shortfall as an opaque transactionError caution,
    // which cannot be identified — let alone replaced — from here.
    open var innerInsufficientBalance: Bool {
        false
    }

    open func cautions(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [CautionNew] {
        var cautions: [CautionNew]

        if innerInsufficientBalance {
            // Replaces the inner's message instead of adding to it: the inner names no amount, and
            // under exact output the figure the user needs is the DEPOSIT, not what they entered.
            // This is the only signal that makes an otherwise baffling rejection intelligible —
            // MAX always fails here by design.
            cautions = [insufficientBalanceCaution()]
        } else {
            cautions = inner.cautions(baseToken: baseToken, currency: currency, rates: rates)
        }

        if attachmentUnsupported {
            cautions.append(CautionNew(
                title: "private_send.caution.title".localized,
                text: "private_send.caution.attachment_unsupported".localized,
                type: .error
            ))
        }

        // Redundant by design: the handler already forbade adjustment on the inner handler. Kept
        // because the failure mode is the recipient receiving nothing while the user believes the
        // send succeeded.
        if inner.amountAdjusted {
            cautions.append(CautionNew(
                title: "private_send.caution.title".localized,
                text: "private_send.caution.amount_adjusted".localized,
                type: .error
            ))
        }

        // The fee shown falls back to the deposit ceiling, so it is an upper bound.
        if order.minSellAmount == nil {
            cautions.append(CautionNew(
                title: "private_send.caution.title".localized,
                text: "private_send.caution.buffer_unknown".localized,
                type: .warning
            ))
        }

        return cautions
    }

    open func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
        let token = order.request.token
        let rate = rates[token.coin.uid]

        let amount = SendField.amount(
            token: token,
            appValueType: .regular(appValue: AppValue(token: token, value: order.amountOut)),
            currencyValue: rate.map { CurrencyValue(currency: currency, value: $0 * order.amountOut) }
        )

        let to = SendField.address(
            value: order.request.recipient,
            blockchainType: token.blockchainType
        )

        var fields: [SendField] = inner.fields(baseToken: baseToken, currency: currency, rates: rates)

        if let estimatedTime = order.estimatedTime {
            fields.append(.simpleValue(
                title: "private_send.estimated_time".localized,
                value: Duration.seconds(estimatedTime).formatted(.units(allowed: [.hours, .minutes, .seconds], width: .narrow))
            ))
        }

        if let buffer = order.refundableBuffer, buffer > 0 {
            fields.append(feeField(
                title: "private_send.reserved_amount".localized,
                info: InfoDescription(title: "private_send.reserved_amount".localized, description: "private_send.reserved_amount.info".localized),
                value: buffer,
                token: token,
                currency: currency,
                rate: rate
            ))
        }

        fields.append(feeField(
            title: "private_send.fee".localized,
            info: InfoDescription(title: "private_send.fee".localized, description: "private_send.fee.info".localized),
            value: order.privateFee,
            token: token,
            currency: currency,
            rate: rate
        ))

        // The inner handler's own rows, in the FEE token — never summed with the rows below.
        fields.append(contentsOf: inner.feeFields(baseToken: baseToken, currency: currency, rates: rates))

        return [.init([amount, to], isFlow: true), .init(fields, isMain: false)]
    }

    private func insufficientBalanceCaution() -> CautionNew {
        let formatted = AppValue(token: order.request.token, value: order.depositAmount).formattedFull() ?? ""

        return CautionNew(
            title: "private_send.caution.title".localized,
            text: "private_send.caution.insufficient_balance %@".localized(formatted),
            type: .error
        )
    }

    private func feeField(title: String, info: InfoDescription, value: Decimal, token: Token, currency: Currency, rate: Decimal?) -> SendField {
        .fee(
            title: ComponentInformedTitle(title, info: info),
            amountData: .init(
                appValue: AppValue(token: token, value: value),
                currencyValue: rate.map { CurrencyValue(currency: currency, value: $0 * value) }
            )
        )
    }
}

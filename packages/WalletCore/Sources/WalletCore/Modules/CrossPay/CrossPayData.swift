import Foundation
import MarketKit

// NOT a PrivateSendData subclass: that class is typed to the single-token PrivateSendOrder.
public class CrossPayData: ISendData {
    // A committed order is only honoured for this long; past it the screen dead-ends.
    public static let quoteLifetime: TimeInterval = 15

    public let order: CrossPayOrder
    public let inner: ISendData
    // The handler that produced `inner`: overlapping sendData calls each prepare their own pair,
    // and broadcasting through the wrong one would use settings the user never confirmed.
    public let innerHandler: ISendHandler
    // ZEC balance snapshot at estimation time, only for the insufficient caution.
    public let availableBalance: Decimal?

    public init(order: CrossPayOrder, inner: ISendData, innerHandler: ISendHandler, availableBalance: Decimal?) {
        self.order = order
        self.inner = inner
        self.innerHandler = innerHandler
        self.availableBalance = availableBalance
    }

    public var feeData: FeeData? {
        inner.feeData
    }

    public var rateCoins: [Coin] {
        inner.rateCoins + [order.request.tokenIn.coin, order.request.tokenOut.coin]
    }

    public var amountAdjusted: Bool {
        inner.amountAdjusted
    }

    public var canSend: Bool {
        // Runs off committedAt, not the screen timer — the gap before the countdown starts must
        // not hold a live slide button over an expired order.
        inner.canSend && !inner.amountAdjusted && Date().timeIntervalSince(order.committedAt) < Self.quoteLifetime
    }

    public var customSendButtonTitle: String? {
        inner.customSendButtonTitle
    }

    public func cautions(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [CautionNew] {
        // The number the user needs is the DEPOSIT — one caution naming it replaces the inner
        // handler's generic refusal.
        if let availableBalance, order.depositAmount > availableBalance {
            return [CautionNew(
                title: "fee_settings.errors.insufficient_balance".localized,
                text: "cross_pay.caution.insufficient_balance %@".localized(Self.formatted(amount: order.depositAmount, token: order.request.tokenIn)),
                type: .error
            )]
        }

        var cautions = inner.cautions(baseToken: baseToken, currency: currency, rates: rates)

        if order.minSellAmount == nil {
            // Without the floor the refundable buffer is unknown, so You Pay is an upper estimate.
            cautions.append(CautionNew(
                title: "cross_pay.you_pay".localized,
                text: "private_send.caution.buffer_unknown".localized,
                type: .warning
            ))
        }

        return cautions
    }

    public func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
        let tokenIn = order.request.tokenIn
        let tokenOut = order.request.tokenOut
        let rateIn = rates[tokenIn.coin.uid]
        let rateOut = rates[tokenOut.coin.uid]

        let amount = SendField.amount(
            token: tokenOut,
            appValueType: .regular(appValue: AppValue(token: tokenOut, value: order.amountOut)),
            currencyValue: rateOut.map { CurrencyValue(currency: currency, value: $0 * order.amountOut) }
        )

        let to = SendField.address(
            value: order.request.recipient,
            blockchainType: tokenOut.blockchainType
        )

        var fields = [SendField]()

        if let estimatedTime = order.estimatedTime {
            fields.append(.simpleValue(
                title: "private_send.estimated_time".localized,
                value: Duration.seconds(estimatedTime).formatted(.units(allowed: [.hours, .minutes, .seconds], width: .narrow))
            ))
        }

        fields.append(feeField(
            title: "cross_pay.you_pay".localized,
            info: InfoDescription(title: "cross_pay.you_pay".localized, description: "cross_pay.you_pay.info".localized),
            value: order.depositAmount,
            token: tokenIn,
            currency: currency,
            rate: rateIn
        ))

        if let buffer = order.refundableBuffer, buffer > 0 {
            fields.append(feeField(
                title: "private_send.reserved_amount".localized,
                info: InfoDescription(title: "private_send.reserved_amount".localized, description: "private_send.reserved_amount.info".localized),
                value: buffer,
                token: tokenIn,
                currency: currency,
                rate: rateIn
            ))
        }

        // The inner handler's own rows, in the FEE token — never summed with the rows above.
        fields.append(contentsOf: inner.feeFields(baseToken: baseToken, currency: currency, rates: rates))

        return [.init([amount, to], isFlow: true), .init(fields, isMain: false)]
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

    private static func formatted(amount: Decimal, token: Token) -> String {
        let figure = ValueFormatter.instance.formatFull(value: amount, decimalCount: token.decimals) ?? "\(amount)"
        return "\(figure) \(token.coin.code)"
    }
}

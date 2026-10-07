import Foundation
import MarketKit

// NOT a PrivateSendData subclass: that class is typed to the single-token PrivateSendPreview.
public class CrossPayData: ISendData {
    // How long a preview is shown before it is silently re-requested. The preview has no side
    // effects, so a refresh costs nothing; the order is created only when the user slides.
    public static let quoteLifetime: TimeInterval = 15

    public let preview: CrossPayPreview
    // The inner send estimated against the preview's stub deposit address: it supplies the network
    // fee rows and the balance vetoes. The one that is broadcast is rebuilt at send time against the
    // committed deposit address, with the same `transactionSettings`.
    public let inner: ISendData
    // The settings the inner send was estimated with, captured so the send-time rebuild against the
    // real deposit address is priced exactly as the user confirmed it. The handler that produced
    // `inner` is not carried: the one that broadcasts is resolved afresh at send time.
    public let transactionSettings: TransactionSettings?
    // ZEC balance snapshot at estimation time, only for the insufficient caution.
    public let availableBalance: Decimal?

    public init(preview: CrossPayPreview, inner: ISendData, transactionSettings: TransactionSettings?, availableBalance: Decimal?) {
        self.preview = preview
        self.inner = inner
        self.transactionSettings = transactionSettings
        self.availableBalance = availableBalance
    }

    public var feeData: FeeData? {
        inner.feeData
    }

    public var rateCoins: [Coin] {
        inner.rateCoins + [preview.request.tokenIn.coin, preview.request.tokenOut.coin]
    }

    public var amountAdjusted: Bool {
        inner.amountAdjusted
    }

    public var canSend: Bool {
        // No lifetime check here: the preview auto-refreshes, and the slide commits whichever
        // preview is on screen. The amountAdjusted veto stays as a structural guard — the handler
        // forbids adjustment before estimation, and the failure mode is the recipient receiving nothing.
        inner.canSend && !inner.amountAdjusted
    }

    public var customSendButtonTitle: String? {
        inner.customSendButtonTitle
    }

    public func cautions(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [CautionNew] {
        // The number the user needs is the DEPOSIT — one caution naming it replaces the inner
        // handler's generic refusal.
        if let availableBalance, preview.depositAmount > availableBalance {
            return [CautionNew(
                title: "fee_settings.errors.insufficient_balance".localized,
                text: "cross_pay.caution.insufficient_balance %@".localized(Self.formatted(amount: preview.depositAmount, token: preview.request.tokenIn)),
                type: .error
            )]
        }

        var cautions = inner.cautions(baseToken: baseToken, currency: currency, rates: rates)

        if preview.minSellAmount == nil {
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
        let tokenIn = preview.request.tokenIn
        let tokenOut = preview.request.tokenOut
        let rateIn = rates[tokenIn.coin.uid]
        let rateOut = rates[tokenOut.coin.uid]

        let amount = SendField.amount(
            token: tokenOut,
            appValueType: .regular(appValue: AppValue(token: tokenOut, value: preview.amountOut)),
            currencyValue: rateOut.map { CurrencyValue(currency: currency, value: $0 * preview.amountOut) }
        )

        let to = SendField.address(
            value: preview.request.recipient,
            blockchainType: tokenOut.blockchainType
        )

        var fields = [SendField]()

        if let estimatedTime = preview.estimatedTime {
            fields.append(.simpleValue(
                title: "private_send.estimated_time".localized,
                value: Duration.seconds(estimatedTime).formatted(.units(allowed: [.hours, .minutes, .seconds], width: .narrow))
            ))
        }

        fields.append(feeField(
            title: "cross_pay.you_pay".localized,
            info: InfoDescription(title: "cross_pay.you_pay".localized, description: "cross_pay.you_pay.info".localized),
            value: preview.depositAmount,
            token: tokenIn,
            currency: currency,
            rate: rateIn,
            isAmount: true
        ))

        if let buffer = preview.refundableBuffer, buffer > 0 {
            fields.append(feeField(
                title: "private_send.reserved_amount".localized,
                info: InfoDescription(title: "private_send.reserved_amount".localized, description: "private_send.reserved_amount.info".localized),
                value: buffer,
                token: tokenIn,
                currency: currency,
                rate: rateIn,
                isAmount: true
            ))
        }

        // The inner handler's own rows, in the FEE token — never summed with the rows above.
        fields.append(contentsOf: inner.feeFields(baseToken: baseToken, currency: currency, rates: rates))

        return [.init([amount, to], isFlow: true), .init(fields, isMain: false)]
    }

    // Amounts open in the coin, fees in fiat; a tap flips either
    private func feeField(title: String, info: InfoDescription, value: Decimal, token: Token, currency: Currency, rate: Decimal?, isAmount: Bool = false) -> SendField {
        SendField(FeeField(
            title: ComponentInformedTitle(title, info: info),
            amountData: .init(
                appValue: AppValue(token: token, value: value),
                currencyValue: rate.map { CurrencyValue(currency: currency, value: $0 * value) }
            ),
            initialFlipped: isAmount
        ))
    }

    private static func formatted(amount: Decimal, token: Token) -> String {
        let figure = ValueFormatter.instance.formatFull(value: amount, decimalCount: token.decimals) ?? "\(amount)"
        return "\(figure) \(token.coin.code)"
    }
}

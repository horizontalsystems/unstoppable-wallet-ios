import Foundation
import MarketKit

// `open`, not `final`: every veto below is identical on both platforms and is written once here,
// while `sections(...)` is the seam each app re-authors in its own SendField idiom.
open class PrivateSendData: ISendData {
    // How long a preview is shown before it is silently re-requested. The preview has no side
    // effects, so a refresh costs nothing; the order is created only when the user slides.
    public static let quoteLifetime: TimeInterval = 15

    public let preview: PrivateSendPreview
    // The inner send estimated against the preview's stub deposit address: it supplies the network
    // fee rows and the balance vetoes. The one that is broadcast is rebuilt at send time against the
    // committed deposit address, with the same `transactionSettings`.
    public let inner: ISendData
    // The settings the inner send was estimated with, captured so the send-time rebuild against the
    // real deposit address is priced exactly as the user confirmed it. The handler that produced
    // `inner` is not carried: the one that broadcasts is resolved afresh at send time.
    public let transactionSettings: TransactionSettings?

    public init(preview: PrivateSendPreview, inner: ISendData, transactionSettings: TransactionSettings?) {
        self.preview = preview
        self.inner = inner
        self.transactionSettings = transactionSettings
    }

    public var feeData: FeeData? {
        inner.feeData
    }

    public var rateCoins: [Coin] {
        inner.rateCoins + [preview.request.token.coin]
    }

    public var amountAdjusted: Bool {
        inner.amountAdjusted
    }

    public var canSend: Bool {
        // No caution accompanies the amountAdjusted veto: the handler forbids adjustment before
        // estimation, so it cannot legitimately be true. It stays only as a structural guard,
        // because the failure mode is the recipient receiving nothing.
        inner.canSend && !inner.amountAdjusted
    }

    public var customSendButtonTitle: String? {
        inner.customSendButtonTitle
    }

    open func cautions(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [CautionNew] {
        inner.cautions(baseToken: baseToken, currency: currency, rates: rates)
    }

    open func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
        let token = preview.request.token
        let rate = rates[token.coin.uid]

        let amount = SendField.amount(
            token: token,
            appValueType: .regular(appValue: AppValue(token: token, value: preview.amountOut)),
            currencyValue: rate.map { CurrencyValue(currency: currency, value: $0 * preview.amountOut) }
        )

        let to = SendField.address(
            value: preview.request.recipient,
            blockchainType: token.blockchainType
        )

        var fields: [SendField] = inner.fields(baseToken: baseToken, currency: currency, rates: rates)

        if let estimatedTime = preview.estimatedTime {
            fields.append(.simpleValue(
                title: "private_send.estimated_time".localized,
                value: Duration.seconds(estimatedTime).formatted(.units(allowed: [.hours, .minutes, .seconds], width: .narrow))
            ))
        }

        if let buffer = preview.refundableBuffer, buffer > 0 {
            fields.append(feeField(
                title: "private_send.reserved_amount".localized,
                info: InfoDescription(title: "private_send.reserved_amount".localized, description: "private_send.reserved_amount.info".localized),
                value: buffer,
                token: token,
                currency: currency,
                rate: rate,
                isAmount: true
            ))
        }

        fields.append(feeField(
            title: "private_send.fee".localized,
            info: InfoDescription(title: "private_send.fee".localized, description: "private_send.fee.info".localized),
            value: preview.privateFee,
            token: token,
            currency: currency,
            rate: rate
        ))

        // The inner handler's own rows, in the FEE token — never summed with the rows below.
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
}

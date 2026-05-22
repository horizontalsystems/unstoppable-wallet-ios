import Foundation
import MarketKit

// Prepends merchant info to inner SendData. NB: recipient name/website are unauthenticated — display only.
class OpenCryptoPaySendData: ISendData {
    let inner: ISendData
    let recipient: OpenCryptoPayPayment.Recipient
    let expirationDate: Date
    let isExpired: Bool

    init(inner: ISendData, recipient: OpenCryptoPayPayment.Recipient, expirationDate: Date, isExpired: Bool) {
        self.inner = inner
        self.recipient = recipient
        self.expirationDate = expirationDate
        self.isExpired = isExpired
    }

    var feeData: FeeData? { inner.feeData }
    var canSend: Bool { isExpired ? false : inner.canSend }
    var rateCoins: [Coin] { inner.rateCoins }
    var customSendButtonTitle: String? {
        isExpired ? "open_crypto_pay.button.expired".localized : inner.customSendButtonTitle
    }

    func cautions(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [CautionNew] {
        inner.cautions(baseToken: baseToken, currency: currency, rates: rates)
    }

    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
        var sections = inner.sections(baseToken: baseToken, currency: currency, rates: rates)

        guard let lastIndex = sections.indices.last else {
            return sections
        }

        let last = sections[lastIndex]
        sections[lastIndex] = SendDataSection(
            [expiresField()] + last.fields,
            isMain: last.isMain,
            isFlow: last.isFlow,
            isList: last.isList
        )
        sections.insert(merchantSection(), at: lastIndex)

        return sections
    }

    private func merchantSection() -> SendDataSection {
        var fields: [SendField] = [
            .simpleValue(
                title: "open_crypto_pay.merchant.name".localized,
                value: recipient.name
            ),
        ]
        if let website = recipient.website {
            fields.append(.simpleValue(
                title: "open_crypto_pay.merchant.url".localized,
                value: website
            ))
        }
        return SendDataSection(fields, isMain: false)
    }

    private func expiresField() -> SendField {
        .timer(
            title: "open_crypto_pay.expires_in".localized,
            expirationDate: expirationDate
        )
    }
}

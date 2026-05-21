import Foundation
import MarketKit

// Prepends merchant info to inner SendData. NB: recipient name/website are unauthenticated — display only.
class OpenCryptoPaySendData: ISendData {
    let inner: ISendData
    let recipient: OpenCryptoPayPayment.Recipient

    init(inner: ISendData, recipient: OpenCryptoPayPayment.Recipient) {
        self.inner = inner
        self.recipient = recipient
    }

    var feeData: FeeData? { inner.feeData }
    var canSend: Bool { inner.canSend }
    var rateCoins: [Coin] { inner.rateCoins }
    var customSendButtonTitle: String? { inner.customSendButtonTitle }

    func cautions(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [CautionNew] {
        inner.cautions(baseToken: baseToken, currency: currency, rates: rates)
    }

    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
        [merchantSection()] + inner.sections(baseToken: baseToken, currency: currency, rates: rates)
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
                title: "open_crypto_pay.merchant.website".localized,
                value: website
            ))
        }
        return SendDataSection(fields, isMain: false)
    }
}

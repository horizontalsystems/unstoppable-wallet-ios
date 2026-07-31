import BigInt
import Foundation
import MarketKit
import ThorChainKit

final class ThorChainSendData: ISendData {
    let token: Token
    let quote: ThorChainKit.SendQuote?
    let transactionError: Error?
    let rateCoins: [Coin]

    init(token: Token, quote: ThorChainKit.SendQuote?, transactionError: Error?) {
        self.token = token
        self.quote = quote
        self.transactionError = transactionError
        rateCoins = [token.coin]
    }

    var feeData: FeeData? { nil }
    var customSendButtonTitle: String? { nil }

    var canSend: Bool {
        quote != nil && transactionError == nil
    }

    func cautions(baseToken: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] {
        transactionError.map { [ThorChainSendHelper.caution($0, feeToken: baseToken)] } ?? []
    }

    func sections(baseToken _: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
        guard let quote,
              let amount = Decimal(bigUInt: quote.amount, decimals: token.decimals),
              let fee = Decimal(bigUInt: quote.nativeFee, decimals: token.decimals)
        else {
            return []
        }

        let amountValue = AppValue(token: token, value: amount)
        let feeValue = AppValue(token: token, value: fee)
        let flowFields: [SendField] = [
            .amount(
                token: token,
                appValueType: .regular(appValue: amountValue),
                currencyValue: rates[token.coin.uid].map { CurrencyValue(currency: currency, value: $0 * amount) }
            ),
            .address(value: quote.recipient.raw, blockchainType: token.blockchainType),
        ]

        var detailsFields = [SendField]()
        if let memo = quote.memo {
            detailsFields.append(.simpleValue(title: "send.confirmation.memo".localized, value: memo))
        }
        detailsFields.append(
            .fee(
                title: ComponentInformedTitle("fee_settings.network_fee".localized, info: .fee),
                amountData: AmountData(
                    appValue: feeValue,
                    currencyValue: rates[token.coin.uid].map { CurrencyValue(currency: currency, value: $0 * fee) }
                )
            )
        )

        return [
            .init(flowFields, isFlow: true),
            .init(detailsFields, isMain: false),
        ]
    }
}

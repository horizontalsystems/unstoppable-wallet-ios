import EvmKit
import Foundation
import MarketKit

class EvmSendData: BaseSendEvmData, ISendData {
    let decoration: EvmDecoration
    let transactionData: TransactionData?
    let transactionError: Error?

    init(decoration: EvmDecoration, transactionData: TransactionData?, transactionError: Error?, gasPrice: GasPrice?, evmFeeData: EvmFeeData?, nonce: Int?) {
        self.decoration = decoration
        self.transactionData = transactionData
        self.transactionError = transactionError

        super.init(gasPrice: gasPrice, evmFeeData: evmFeeData, nonce: nonce)
    }

    var feeData: FeeData? {
        evmFeeData.map { .evm(evmFeeData: $0) }
    }

    var canSend: Bool {
        evmFeeData != nil && transactionError == nil
    }

    var rateCoins: [Coin] {
        decoration.rateCoins
    }

    var customSendButtonTitle: String? {
        decoration.customSendButtonTitle
    }

    func cautions(baseToken: Token) -> [CautionNew] {
        var cautions = [CautionNew]()

        if let transactionError {
            cautions.append(caution(transactionError: transactionError, feeToken: baseToken))
        }

        return cautions
    }

    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [[SendField]] {
        var sections = decoration.sections(baseToken: baseToken, currency: currency, rates: rates)

        if let nonce {
            sections.append(
                [
                    .levelValue(title: "send.confirmation.nonce".localized, value: String(nonce), level: .regular),
                ]
            )
        }

        sections.append(feeFields(feeToken: baseToken, currency: currency, feeTokenRate: rates[baseToken.coin.uid]))

        return sections
    }
}

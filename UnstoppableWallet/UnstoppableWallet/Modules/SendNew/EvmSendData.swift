import EvmKit
import Foundation
import MarketKit
import SwiftUI

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

    func cautions(baseToken: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] {
        var cautions = [CautionNew]()

        if let transactionError {
            cautions.append(caution(transactionError: transactionError, feeToken: baseToken))
        }

        return cautions
    }

    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
        let flow = decoration.flowSection(baseToken: baseToken, currency: currency, rates: rates)
        var fields = decoration.fields(baseToken: baseToken, currency: currency, rates: rates)

        if let nonce {
            fields.append(
                .simpleValue(title: "send.confirmation.nonce".localized, value: String(nonce)),
            )
        }

        fields.append(contentsOf: feeFields(feeToken: baseToken, currency: currency, feeTokenRate: rates[baseToken.coin.uid]))

        return [flow, .init(fields)].compactMap { $0 }
    }
}

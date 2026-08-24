import EvmKit
import Foundation
import MarketKit
import SwiftUI

class EvmSendData: ISendData {
    let decoration: EvmDecoration
    let transactionData: TransactionData?
    let transactionError: Error?
    let gasPrice: GasPrice?
    let evmFeeData: EvmFeeData?
    let nonce: Int?

    init(decoration: EvmDecoration, transactionData: TransactionData?, transactionError: Error?, gasPrice: GasPrice?, evmFeeData: EvmFeeData?, nonce: Int?) {
        self.decoration = decoration
        self.transactionData = transactionData
        self.transactionError = transactionError
        self.gasPrice = gasPrice
        self.evmFeeData = evmFeeData
        self.nonce = nonce
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
            cautions.append(EvmSendHelper.caution(transactionError: transactionError, feeToken: baseToken))
        }

        return cautions
    }

    func fields(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendField] {
        var fields = decoration.fields(baseToken: baseToken, currency: currency, rates: rates)

        if let nonce {
            fields.append(.simpleValue(title: "send.confirmation.nonce".localized, value: String(nonce)))
        }

        return fields
    }

    func feeFields(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendField] {
        EvmSendHelper.feeFields(evmFeeData: evmFeeData, gasPrice: gasPrice, feeToken: baseToken, currency: currency, feeTokenRate: rates[baseToken.coin.uid])
    }

    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
        let flow = decoration.flowSection(baseToken: baseToken, currency: currency, rates: rates)
        let fields = fields(baseToken: baseToken, currency: currency, rates: rates)
        let feeFields = feeFields(baseToken: baseToken, currency: currency, rates: rates)

        return [flow, .init(fields + feeFields, isMain: false)].compactMap { $0 }
    }
}

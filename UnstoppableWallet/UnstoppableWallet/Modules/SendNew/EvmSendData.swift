import EvmKit
import Foundation
import MarketKit
import SwiftUI

class EvmSendData: BaseSendEvmData, ISendData {
    let decoration: EvmDecoration
    let transactionData: TransactionData?
    let transactionError: Error?

    @Binding var useMevProtection: Bool?

    init(decoration: EvmDecoration, transactionData: TransactionData?, transactionError: Error?, gasPrice: GasPrice?, evmFeeData: EvmFeeData?, nonce: Int?, useMevProtection: Binding<Bool?>) {
        self.decoration = decoration
        self.transactionData = transactionData
        self.transactionError = transactionError

        _useMevProtection = useMevProtection

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

    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
        var sections = decoration.sections(baseToken: baseToken, currency: currency, rates: rates)

        if let nonce {
            sections.append(
                .init([
                    .levelValue(title: "send.confirmation.nonce".localized, value: String(nonce), level: .regular),
                ])
            )
        }

        sections.append(.init(feeFields(feeToken: baseToken, currency: currency, feeTokenRate: rates[baseToken.coin.uid])))

        return sections
    }
}

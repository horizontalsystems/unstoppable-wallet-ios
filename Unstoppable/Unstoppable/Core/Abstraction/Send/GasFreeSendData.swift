import BigInt
import Foundation
import MarketKit
import SwiftUI
import TronKit
import WalletCore

class GasFreeSendData: ISendData {
    let prepared: PreparedGasFreeTransfer
    let token: Token

    init(prepared: PreparedGasFreeTransfer, token: Token) {
        self.prepared = prepared
        self.token = token
    }

    var feeData: FeeData? {
        // Edit Fee menu hidden — fees come from GasFree provider, not user-tunable.
        nil
    }

    var canSend: Bool {
        // GasFreeSender.prepare throws on any RPC / signing failure; reaching here means
        // the SubmitTransferRequest is fully assembled bar the signature.
        true
    }

    var rateCoins: [Coin] {
        [token.coin]
    }

    func cautions(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] {
        []
    }

    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
        let tokenRate = rates[token.coin.uid]
        let value = Decimal(bigUInt: prepared.value, decimals: token.decimals) ?? 0

        let flow = SendDataSection(
            [
                .amount(
                    token: token,
                    appValueType: .regular(appValue: AppValue(token: token, value: value)),
                    currencyValue: tokenRate.map { CurrencyValue(currency: currency, value: $0 * value) }
                ),
                .address(value: prepared.receiver.base58, blockchainType: token.blockchainType),
            ],
            isFlow: true
        )

        var fields: [SendField] = []

        let breakdown = prepared.feeBreakdown
        let feeTokenRate = rates[baseToken.coin.uid]

        fields.append(.fee(
            title: "send.fee.transfer".localized,
            amountData: amountData(rawTokenAmount: breakdown.transferFee, baseToken: baseToken, currency: currency, feeTokenRate: feeTokenRate)
        ))

        if breakdown.activateFee > 0 {
            fields.append(.fee(
                title: "send.fee.activation".localized,
                amountData: amountData(rawTokenAmount: breakdown.activateFee, baseToken: baseToken, currency: currency, feeTokenRate: feeTokenRate)
            ))
        }

        switch breakdown.scenario {
        case .activateAndTransfer:
            fields.append(.note(iconName: nil, title: "send.fee.includes_activation".localized))
        case .transfer:
            ()
        }

        return [flow, .init(fields, isMain: false)]
    }

    private func amountData(rawTokenAmount: BigUInt, baseToken: Token, currency: Currency, feeTokenRate: Decimal?) -> AmountData? {
        guard let amount = Decimal(bigUInt: rawTokenAmount, decimals: baseToken.decimals) else {
            return nil
        }

        let appValue = AppValue(token: baseToken, value: amount)
        let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: amount * $0) }

        return AmountData(appValue: appValue, currencyValue: currencyValue)
    }
}

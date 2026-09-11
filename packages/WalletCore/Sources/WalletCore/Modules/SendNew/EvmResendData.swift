import BigInt
import EvmKit
import Foundation
import MarketKit

class EvmResendData: EvmSendData {
    let swap: EvmResendSwapData?

    init(decoration: EvmDecoration, swap: EvmResendSwapData?, transactionData: TransactionData, transactionError: Error?, gasPrice: GasPrice?, evmFeeData: EvmFeeData?, nonce: Int?) {
        self.swap = swap
        super.init(decoration: decoration, transactionData: transactionData, transactionError: transactionError, gasPrice: gasPrice, evmFeeData: evmFeeData, nonce: nonce)
    }

    override var rateCoins: [Coin] {
        guard let swap else { return super.rateCoins }
        return [swap.tokenIn.coin, swap.tokenOut.coin]
    }

    override var customSendButtonTitle: String? {
        // Replacement confirmation chooses its own action, including for an approve payload.
        nil
    }

    override func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
        guard let swap else {
            return super.sections(baseToken: baseToken, currency: currency, rates: rates)
        }

        var amounts = [SendField]()
        if case let .exact(value) = swap.amountIn {
            amounts.append(flowAmount(token: swap.tokenIn, value: value, currency: currency, rates: rates))
        }
        // No estimate survives in the transaction. A minimum is not an expected output.
        if swap.kind == .uniswap, case let .exact(value) = swap.amountOut {
            amounts.append(flowAmount(token: swap.tokenOut, value: value, currency: currency, rates: rates))
        }

        var sections: [SendDataSection] = [.init(amounts, isFlow: true)]
        let nonceFields: [SendField] = nonce.map { [.simpleValue(title: "send.confirmation.nonce".localized, value: String($0))] } ?? []
        if swap.kind == .oneInch, !nonceFields.isEmpty {
            sections.append(.init(nonceFields))
        }

        var details = [SendField]()
        if let recipient = swap.recipient {
            details.append(.recipient(title: "swap.advanced_settings.recipient_address".localized, value: recipient.eip55, copyable: true, blockchainType: baseToken.blockchainType))
        }
        if case let .extremum(value) = swap.amountIn {
            details.append(amount(title: "swap.confirmation.maximum_sent".localized, token: swap.tokenIn, value: value, currency: currency, rates: rates))
        } else if case let .extremum(value) = swap.amountOut {
            details.append(amount(title: "swap.confirmation.minimum_received".localized, token: swap.tokenOut, value: value, currency: currency, rates: rates))
        }
        if swap.kind == .uniswap {
            details.append(contentsOf: nonceFields)
        }
        if !details.isEmpty {
            sections.append(.init(details))
        }
        sections.append(.init(feeFields(baseToken: baseToken, currency: currency, rates: rates)))
        return sections
    }

    private func amount(title: String, token: Token, value: BigUInt, currency: Currency, rates: [String: Decimal]) -> SendField {
        let amount = token.decimalValue(value: value)
        return .value(
            title: title,
            appValue: AppValue(token: token, value: amount),
            currencyValue: rates[token.coin.uid].map { CurrencyValue(currency: currency, value: amount * $0) },
            formatFull: true
        )
    }

    private func flowAmount(token: Token, value: BigUInt, currency: Currency, rates: [String: Decimal]) -> SendField {
        let amount = token.decimalValue(value: value)
        return .amount(
            token: token,
            appValueType: .regular(appValue: AppValue(token: token, value: amount)),
            currencyValue: rates[token.coin.uid].map { CurrencyValue(currency: currency, value: amount * $0) }
        )
    }
}

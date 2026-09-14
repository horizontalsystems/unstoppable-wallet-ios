import BigInt
import EvmKit
import Foundation
import MarketKit
import class UniswapKit.SwapDecoration

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

    override func feeFields(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendField] {
        super.feeFields(baseToken: baseToken, currency: currency, rates: rates).map { field in
            guard let fee = field.content as? FeeField else { return field }
            return SendField(FeeField(title: fee.title, amountData: fee.amountData, initialFlipped: true))
        }
    }

    override func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
        guard let swap else {
            return super.sections(baseToken: baseToken, currency: currency, rates: rates)
        }
        var sections = [
            swapSection(token: swap.tokenIn, amount: swap.amountIn, incoming: false, currency: currency, rates: rates),
            swapSection(token: swap.tokenOut, amount: swap.amountOut, incoming: true, currency: currency, rates: rates),
        ]
        if let recipient = swap.recipient {
            sections.append(.init([.address(value: recipient.eip55, blockchainType: baseToken.blockchainType)]))
        }
        var settings: [SendField] = nonce.map { [.simpleValue(title: "send.confirmation.nonce".localized, value: String($0))] } ?? []
        settings += feeFields(baseToken: baseToken, currency: currency, rates: rates)
        sections.append(.init(settings, isMain: false))
        return sections
    }

    private func swapSection(token: Token, amount: SwapDecoration.Amount, incoming: Bool, currency: Currency, rates: [String: Decimal]) -> SendDataSection {
        let value: BigUInt
        let suffix: String?
        switch amount {
        case let .exact(exact):
            value = exact
            suffix = nil
        case let .extremum(limit):
            value = limit
            suffix = (incoming ? "swap.amount_min" : "swap.amount_max").localized
        }
        let decimalValue = token.decimalValue(value: value)
        return .init([
            SendField(SimpleValueField(
                icon: incoming ? "arrow_medium_main_down_left_20" : "arrow_medium_main_up_right_20",
                title: ComponentText(text: (incoming ? "swap.you_get" : "swap.you_pay").localized, colorStyle: .primary),
                value: ComponentText(text: token.coin.name, colorStyle: .secondary),
                isPrimary: true
            )),
            SendField(SwapAmountField(
                token: token, appValue: AppValue(token: token, value: decimalValue),
                currencyValue: rates[token.coin.uid].map { CurrencyValue(currency: currency, value: decimalValue * $0) },
                incoming: incoming, suffix: suffix
            )),
        ], isFlow: true)
    }
}

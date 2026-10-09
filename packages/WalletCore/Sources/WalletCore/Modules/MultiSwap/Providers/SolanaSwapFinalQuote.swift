import Foundation
import MarketKit

class SolanaSwapFinalQuote: SwapFinalQuote {
    let rawTransaction: Data?
    // plain transfer built locally for a USwap transfer route (no server transaction)
    let transfer: SolanaTransferExecution?
    private let fee: Decimal?

    init(
        rawTransaction: Data?,
        transfer: SolanaTransferExecution? = nil,
        expectedAmountOut: Decimal,
        recipient: String?,
        slippage: Decimal?,
        estimatedTime: TimeInterval? = nil,
        fee: Decimal?,
        transactionError: Error?,
        toAddress: String,
        depositAddress: String?,
        providerSwapId: String?
    ) {
        self.rawTransaction = rawTransaction
        self.transfer = transfer
        self.fee = fee

        super.init(expectedBuyAmount: expectedAmountOut, slippage: slippage, recipient: recipient, estimatedTime: estimatedTime, transactionError: transactionError, toAddress: toAddress, depositAddress: depositAddress, providerSwapId: providerSwapId)
    }

    private var kind: SolanaExecutable.Kind? {
        if let rawTransaction {
            return .raw(rawTransaction)
        }
        if let transfer {
            return .transfer(transfer)
        }
        return nil
    }

    override var canSwap: Bool {
        super.canSwap && fee != nil && kind != nil
    }

    override func buildExecutable(tokenIn: Token) -> ISwapExecutable {
        SolanaExecutable(token: tokenIn, kind: kind)
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        let title: String
        let text: String

        if let solanaError = transactionError as? SolanaSendHandler.TransactionError {
            switch solanaError {
            case let .insufficientSolBalance(balance):
                let appValue = AppValue(token: baseToken, value: balance)
                let balanceString = appValue.formattedShort()

                title = "fee_settings.errors.insufficient_balance".localized
                text = "fee_settings.errors.insufficient_balance.info".localized(balanceString ?? "")

            case let .insufficientTokenBalance(balance, token):
                // The sold token, not baseToken: an SPL shortfall formatted with SOL decimals would
                // show a wrong figure, not merely a wrong symbol.
                let appValue = AppValue(token: token, value: balance)
                let balanceString = appValue.formattedShort()

                title = "fee_settings.errors.insufficient_balance".localized
                text = "fee_settings.errors.insufficient_balance.info".localized(balanceString ?? "")
            }
        } else {
            title = "ethereum_transaction.error.title".localized
            text = transactionError.convertedError.smartDescription
        }

        return CautionNew(title: title, text: text, type: .error)
    }

    override func feeFields(baseToken: Token, currency: Currency, baseTokenRate: Decimal?) -> [SendField] {
        guard let fee else {
            return []
        }

        let appValue = AppValue(token: baseToken, value: fee)
        let currencyValue = baseTokenRate.map { CurrencyValue(currency: currency, value: fee * $0) }

        return [
            .fee(
                title: ComponentInformedTitle("fee_settings.network_fee".localized, info: .fee),
                amountData: .init(appValue: appValue, currencyValue: currencyValue)
            ),
        ]
    }
}

import EvmKit
import Foundation
import MarketKit

class BaseSendEvmData {
    let gasPrice: GasPrice?
    let evmFeeData: EvmFeeData?
    let nonce: Int?

    init(gasPrice: GasPrice?, evmFeeData: EvmFeeData?, nonce: Int?) {
        self.gasPrice = gasPrice
        self.evmFeeData = evmFeeData
        self.nonce = nonce
    }

    func feeSection(feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> [SendConfirmField] {
        let amountData = evmFeeData.flatMap { $0.totalAmountData(gasPrice: gasPrice, feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate) }

        return [
            .value(
                title: "fee_settings.network_fee".localized,
                description: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized),
                coinValue: amountData?.coinValue,
                currencyValue: amountData?.currencyValue,
                formatFull: true
            ),
        ]
    }

    func caution(transactionError: Error, feeToken: Token?) -> CautionNew {
        let title: String
        let text: String

        if case let AppError.ethereum(reason) = transactionError.convertedError {
            switch reason {
            case .insufficientBalanceWithFee:
                title = "fee_settings.errors.insufficient_balance".localized
                text = "ethereum_transaction.error.insufficient_balance_with_fee".localized(feeToken?.coin.code ?? "")
            case let .executionReverted(message):
                title = "fee_settings.errors.unexpected_error".localized
                text = message
            case .lowerThanBaseGasLimit:
                title = "fee_settings.errors.low_max_fee".localized
                text = "fee_settings.errors.low_max_fee.info".localized
            case .nonceAlreadyInBlock:
                title = "fee_settings.errors.nonce_already_in_block".localized
                text = "ethereum_transaction.error.nonce_already_in_block".localized
            case .replacementTransactionUnderpriced:
                title = "fee_settings.errors.replacement_transaction_underpriced".localized
                text = "ethereum_transaction.error.replacement_transaction_underpriced".localized
            case .transactionUnderpriced:
                title = "fee_settings.errors.transaction_underpriced".localized
                text = "ethereum_transaction.error.transaction_underpriced".localized
            case .tipsHigherThanMaxFee:
                title = "fee_settings.errors.tips_higher_than_max_fee".localized
                text = "ethereum_transaction.error.tips_higher_than_max_fee".localized
            }
        } else {
            title = "ethereum_transaction.error.title".localized
            text = transactionError.convertedError.smartDescription
        }

        return CautionNew(title: title, text: text, type: .error)
    }
}

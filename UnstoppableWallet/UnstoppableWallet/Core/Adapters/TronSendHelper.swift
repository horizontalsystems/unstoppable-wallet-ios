import BigInt
import Foundation
import MarketKit
import TronKit

class TronSendHelper {
    static func estimateFees(
        createdTransaction: TronKit.CreatedTransactionResponse,
        tronKit: TronKit.Kit,
        tokenIn: Token,
        amountIn: Decimal
    ) async throws -> FeeEstimationResult {
        let trxBalance = tronKit.trxBalance

        do {
            let fees = try await tronKit.estimateFee(createdTransaction: createdTransaction)
            let totalFees = fees.calculateTotalFees()

            var totalAmount = 0

            // Add native token amount if sending TRX
            if tokenIn.type.isNative,
               let sendAmount = tokenIn.rawAmount(amountIn),
               let sendAmountInt = Int(sendAmount.description)
            {
                totalAmount += sendAmountInt
            }

            totalAmount += totalFees

            // Validate balance
            if trxBalance < totalAmount {
                let error = TransactionError.insufficientBalance(balance: trxBalance)
                return FeeEstimationResult(
                    fees: fees,
                    totalFees: totalFees,
                    totalAmount: totalAmount,
                    transactionError: error
                )
            }

            return FeeEstimationResult(
                fees: fees,
                totalFees: totalFees,
                totalAmount: totalAmount,
                transactionError: nil
            )
        } catch {
            throw error
        }
    }

    static func validateBalance(
        tronKit: TronKit.Kit,
        totalAmount: Int
    ) throws {
        let trxBalance = tronKit.trxBalance

        guard trxBalance >= totalAmount else {
            throw TransactionError.insufficientBalance(balance: trxBalance)
        }
    }
}

// UI Part
extension TronSendHelper {
    static func caution(transactionError: Error, feeToken: Token) -> CautionNew {
        let title: String
        let text: String

        if let tronError = transactionError as? TronSendHelper.TransactionError {
            switch tronError {
            case let .insufficientBalance(balance):
                let appValue = AppValue(token: feeToken, value: balance.toDecimal(decimals: feeToken.decimals) ?? 0)
                let balanceString = appValue.formattedShort()

                title = "fee_settings.errors.insufficient_balance".localized
                text = "fee_settings.errors.insufficient_balance.info".localized(balanceString ?? "")

            case .zeroAmount:
                title = "alert.error".localized
                text = "fee_settings.errors.zero_amount.info".localized
            }
        } else {
            title = "Error"
            text = transactionError.convertedError.smartDescription
        }

        return CautionNew(title: title, text: text, type: .error)
    }

    static func feeFields(baseToken: Token, totalFees: Int?, fees: [Fee]?, currency: Currency, feeTokenRate: Decimal?) -> [SendField] {
        var viewItems = [SendField]()

        if let totalFees {
            let decimalAmount = Decimal(totalFees) / pow(10, baseToken.decimals)
            let appValue = AppValue(token: baseToken, value: decimalAmount)
            let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: decimalAmount * $0) }

            viewItems.append(
                .value(
                    title: SendField.InformedTitle("fee_settings.network_fee".localized, info: .fee),
                    appValue: appValue,
                    currencyValue: currencyValue,
                    formatFull: true
                )
            )
        }

        if let fees {
            var bandwidth: String?
            var energy: String?

            for fee in fees {
                switch fee {
                case let .accountActivation(amount):
                    let decimalAmount = Decimal(amount) / pow(10, baseToken.decimals)
                    let appValue = AppValue(token: baseToken, value: decimalAmount)
                    let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: decimalAmount * $0) }

                    let info = InfoDescription(title: "tron.send.activation_fee".localized, description: "tron.send.activation_fee.info".localized)

                    viewItems.append(
                        .value(
                            title: SendField.InformedTitle("tron.send.activation_fee".localized, info: info),
                            appValue: appValue,
                            currencyValue: currencyValue,
                            formatFull: true
                        )
                    )

                case let .bandwidth(points, _):
                    bandwidth = ValueFormatter.instance.formatShort(value: Decimal(points), decimalCount: 0)

                case let .energy(required, _):
                    energy = ValueFormatter.instance.formatShort(value: Decimal(required), decimalCount: 0)
                }
            }

            if bandwidth != nil || energy != nil {
                viewItems.append(
                    .doubleValue(
                        title: "tron.send.resources_consumed".localized,
                        description: .init(title: "tron.send.resources_consumed".localized, description: "tron.send.resources_consumed.info".localized),
                        value1: bandwidth.flatMap { "\($0) \("tron.send.bandwidth".localized)" } ?? "",
                        value2: energy.flatMap { "\($0) \("tron.send.energy".localized)" }
                    )
                )
            }
        }

        return viewItems
    }
}

extension TronSendHelper {
    struct FeeEstimationResult {
        let fees: [TronKit.Fee]
        let totalFees: Int
        let totalAmount: Int // includes value + fees
        let transactionError: Error?
    }

    enum TransactionError: Error {
        case insufficientBalance(balance: BigUInt)
        case zeroAmount
    }
}

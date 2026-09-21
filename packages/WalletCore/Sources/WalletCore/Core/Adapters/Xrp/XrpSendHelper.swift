import Foundation
import MarketKit

/// One place for the XRP transaction errors and the fields that render them, shared by the send
/// handler and the swap deposit leg (StellarSendHelper form).
enum XrpSendHelper {
    static func caution(transactionError: Error, feeToken: Token) -> CautionNew {
        let title: String
        let text: String

        if let xrpError = transactionError as? TransactionError {
            switch xrpError {
            case let .insufficientXrpBalance(balance):
                let balanceString = AppValue(token: feeToken, value: balance).formattedShort()

                title = "fee_settings.errors.insufficient_balance".localized
                text = "fee_settings.errors.insufficient_balance.info".localized(balanceString ?? "")
            case .insufficientTokenBalance:
                title = "fee_settings.errors.insufficient_balance".localized
                text = "swap.insufficient_balance".localized
            case .insufficientActivationBalance:
                title = "fee_settings.errors.insufficient_balance".localized
                text = "send.xrp.activation.insufficient_balance".localized
            case let .belowMinimumFirstDeposit(minimum):
                let minimumString = AppValue(token: feeToken, value: minimum).formattedFull()

                title = "send.amount_error.minimum_amount.title".localized
                text = "send.amount_error.minimum_amount.description".localized(minimumString ?? "")
            case .destinationRequiresTag:
                title = "send.xrp.destination_tag".localized
                text = "send.xrp.destination_tag.required".localized
            }
        } else {
            title = "ethereum_transaction.error.title".localized
            text = transactionError.convertedError.smartDescription
        }

        return CautionNew(title: title, text: text, type: .error)
    }

    /// The gates that need the ledger's answer about the recipient, asked at the confirmation and
    /// re-asked on every refresh (Android `SendTransactionServiceXrp.cautions`): an account that is
    /// not on the ledger yet is created by this payment, which the network accepts only from the
    /// base reserve upwards (tecNO_DST_INSUF_XRP), and an untagged payment to an account flagged
    /// RequireDestTag is refused. A lookup that failed blocks the send too: an unknown flag is not
    /// the same as no flag. The send form stays permissive, so this screen is where the retry lives.
    static func destinationError(adapter: ISendXrpAdapter, token: Token, amount: Decimal, address: String, destinationTag: UInt32?) async -> Error? {
        do {
            if token.type.isNative {
                let exists = try await adapter.doesAccountExist(address: address)

                if !exists, amount < adapter.baseReserve {
                    return TransactionError.belowMinimumFirstDeposit(minimum: adapter.baseReserve)
                }
            }

            if destinationTag == nil {
                let requiresTag = try await adapter.requiresDestinationTag(address: address)

                if requiresTag {
                    return TransactionError.destinationRequiresTag
                }
            }

            return nil
        } catch {
            return error
        }
    }

    static func feeFields(fee: Decimal?, feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> [SendField] {
        guard let fee else {
            return []
        }

        let appValue = AppValue(token: feeToken, value: fee)
        let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: fee * $0) }

        return [
            .fee(
                title: ComponentInformedTitle("fee_settings.network_fee".localized, info: .fee),
                amountData: .init(appValue: appValue, currencyValue: currencyValue)
            ),
        ]
    }
}

extension XrpSendHelper {
    enum TransactionError: Error {
        case insufficientXrpBalance(balance: Decimal)
        case insufficientTokenBalance
        /// A TrustSet locks one owner reserve increment on top of the fee.
        case insufficientActivationBalance
        /// The destination account does not exist: its first payment has to cover the base reserve.
        case belowMinimumFirstDeposit(minimum: Decimal)
        /// The destination carries the RequireDestTag flag and the route brought no tag.
        case destinationRequiresTag
    }
}

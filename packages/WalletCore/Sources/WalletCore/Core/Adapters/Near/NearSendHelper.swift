import Foundation
import MarketKit
import NearKit

/// One place for the NEAR transaction errors and the fields that render them, shared by the send
/// handler and the swap deposit leg (Android `SendTransactionServiceNear`).
///
/// The fee is only known once the receiver is: a transfer to an implicit account pays for creating
/// it, and a token send to an unregistered account also pays its storage deposit. Both come out of
/// the NEAR balance, which must also cover gas bought up front at a price above the one finally
/// charged, so the check is against the estimate's required balance, not the fee.
enum NearSendHelper {
    struct Estimation {
        let estimate: NearSendEstimate?
        let transactionError: Error?
    }

    static func estimation(adapter: ISendNearAdapter, token: Token, amount: Decimal, address: String, memo: String?, tokenBalance: Decimal) async -> Estimation {
        do {
            let estimate = try await adapter.estimate(address: address, amount: amount, memo: memo)
            let error = transactionError(token: token, amount: amount, tokenBalance: tokenBalance, availableNear: adapter.availableNear, estimate: estimate)
            return Estimation(estimate: estimate, transactionError: error)
        } catch {
            // without an estimate the balance cannot be checked, so the send stays blocked
            if case .storageDepositTooHigh = error as? NearKit.SendError {
                return Estimation(estimate: nil, transactionError: TransactionError.storageDepositTooHigh)
            }
            return Estimation(estimate: nil, transactionError: error)
        }
    }

    static func transactionError(token: Token, amount: Decimal, tokenBalance: Decimal, availableNear: Decimal, estimate: NearSendEstimate) -> Error? {
        if !token.type.isNative, amount > tokenBalance {
            return TransactionError.insufficientTokenBalance
        }

        if availableNear < estimate.requiredNear {
            return TransactionError.insufficientNearBalance(required: estimate.requiredNear)
        }

        return nil
    }

    static func caution(transactionError: Error, feeToken: Token) -> CautionNew {
        let title: String
        let text: String

        if let nearError = transactionError as? TransactionError {
            switch nearError {
            case let .insufficientNearBalance(required):
                // the required balance is well above the fee shown, so the amount to top up is named
                let requiredString = AppValue(token: feeToken, value: required).formattedFull()

                title = "fee_settings.errors.insufficient_balance".localized
                text = "transaction.error.insufficient_balance".localized(requiredString ?? "")
            case .insufficientTokenBalance:
                title = "fee_settings.errors.insufficient_balance".localized
                text = "swap.insufficient_balance".localized
            case .storageDepositTooHigh:
                title = "alert.warning".localized
                text = "send.near.storage_deposit_too_high".localized
            }
        } else {
            title = "ethereum_transaction.error.title".localized
            text = transactionError.convertedError.smartDescription
        }

        return CautionNew(title: title, text: text, type: .error)
    }

    /// The kit keeps a send whose outcome it could not learn as pending; another send now could
    /// pay twice. A warning only, as on Android.
    static func pendingCaution() -> CautionNew {
        CautionNew(title: "alert.warning".localized, text: "send.near.previous_transaction_pending".localized, type: .warning)
    }

    static func feeFields(fee: Decimal?, storageDeposit: Decimal?, feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> [SendField] {
        var fields = [SendField]()

        if let fee {
            let appValue = AppValue(token: feeToken, value: fee)
            let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: fee * $0) }

            fields.append(
                .fee(
                    title: ComponentInformedTitle("fee_settings.network_fee".localized, info: .fee),
                    amountData: .init(appValue: appValue, currencyValue: currencyValue)
                )
            )
        }

        // what the token contract charges once to register a receiver that never held the token
        if let storageDeposit {
            let appValue = AppValue(token: feeToken, value: storageDeposit)
            let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: storageDeposit * $0) }
            let info = InfoDescription(title: "send.near.receiver_registration".localized, description: "send.near.receiver_registration.info".localized)

            fields.append(
                .value(
                    title: ComponentInformedTitle("send.near.receiver_registration".localized, info: info),
                    appValue: appValue,
                    currencyValue: currencyValue,
                    formatFull: true
                )
            )
        }

        return fields
    }

    /// Past signing, the kit keeps a transaction that may have reached a node as pending, and it
    /// resolves in the history; reporting a failure then would invite a second send. So a failed
    /// broadcast that left a new pending transaction is a success, as on Android. Failures before
    /// signing leave no record.
    static func send(adapter: ISendNearAdapter, amount: Decimal, address: String, memo: String?, estimate: NearSendEstimate, signer: NearKit.Signer) async throws -> String {
        let pendingBefore = adapter.pendingTransactionHashes

        do {
            return try await adapter.send(amount: amount, address: address, memo: memo, estimate: estimate, signer: signer)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as NearKit.SendError {
            switch error {
            // the confirmation showed another deposit; the next refresh shows the new one
            case .storageDepositChanged: throw SendError.storageDepositChanged
            case .storageDepositTooHigh: throw SendError.storageDepositTooHigh
            case let .rejected(details):
                // kept as pending when the kit cannot tell whether an earlier attempt got it on chain
                if let hash = newPendingHash(adapter: adapter, pendingBefore: pendingBefore) {
                    return hash
                }
                throw rejectedError(details: details)
            default: throw error
            }
        } catch {
            if let hash = newPendingHash(adapter: adapter, pendingBefore: pendingBefore) {
                return hash
            }
            throw isNoConnection(error) ? AppError.noConnection : error
        }
    }

    private static func newPendingHash(adapter: ISendNearAdapter, pendingBefore: Set<String>) -> String? {
        adapter.pendingTransactionHashes.subtracting(pendingBefore).first
    }

    // details is the node's InvalidTxError, e.g. {"TxExecutionError":{"InvalidTxError":{"NotEnoughBalance":…}}}
    static func rejectedError(details: String) -> SendError {
        if details.contains("NotEnoughBalance") || details.contains("LackBalanceForState") {
            return .insufficientBalance
        }
        return .rejected
    }

    // the kit wraps the transport error in NoEndpointAvailable once every endpoint has failed
    private static func isNoConnection(_ error: Error) -> Bool {
        var current: Error? = error

        while let error = current {
            if let urlError = error as? URLError, [.notConnectedToInternet, .cannotFindHost, .dnsLookupFailed, .networkConnectionLost].contains(urlError.code) {
                return true
            }
            if case .noConnection? = error.convertedError as? AppError {
                return true
            }
            current = (error as? NoEndpointAvailable)?.underlying
        }

        return false
    }
}

extension NearSendHelper {
    enum TransactionError: Error {
        /// The NEAR balance does not cover what the network needs to accept the send.
        case insufficientNearBalance(required: Decimal)
        case insufficientTokenBalance
        /// The token contract asks an unusual deposit to register the receiver.
        case storageDepositTooHigh
    }

    enum SendError: LocalizedError {
        case storageDepositChanged
        case storageDepositTooHigh
        case rejected
        case insufficientBalance

        var errorDescription: String? {
            switch self {
            case .storageDepositChanged: return "send.near.storage_deposit_changed".localized
            case .storageDepositTooHigh: return "send.near.storage_deposit_too_high".localized
            case .rejected: return "send.near.rejected".localized
            case .insufficientBalance: return "fee_settings.errors.insufficient_balance".localized
            }
        }
    }
}

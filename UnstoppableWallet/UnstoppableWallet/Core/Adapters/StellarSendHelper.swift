import Foundation
import MarketKit
import StellarKit
import stellarsdk

class StellarSendHelper {
    static func validate(accountId: String) throws {
        try StellarKit.Kit.validate(accountId: accountId)
    }

    static func preparePayment(
        asset: StellarKit.Asset,
        amount: Decimal,
        accountId: String,
        stellarKit: StellarKit.Kit
    ) async throws -> PaymentResult {
        let baseFee = try await stellarKit.baseFee()
        let stellarBalance = stellarKit.account?.assetBalanceMap[.native]?.balance ?? 0

        var adjustedAmount = amount

        // Adjust amount if sending all native balance
        if asset.isNative, amount == stellarBalance {
            adjustedAmount -= baseFee
        }

        // Calculate total native amount needed
        var totalNativeAmount: Decimal = baseFee
        if asset.isNative {
            totalNativeAmount += adjustedAmount
        }

        // Validate balance
        guard stellarBalance >= totalNativeAmount else {
            throw TransactionError.insufficientStellarBalance(balance: stellarBalance)
        }

        // Build operation
        let destinationAccount = try await StellarKit.Kit.account(accountId: accountId)
        let operation: stellarsdk.Operation

        if let destinationAccount {
            guard destinationAccount.assetBalanceMap[asset] != nil else {
                throw TransactionError.noTrustline
            }

            operation = try stellarKit.paymentOperation(
                asset: asset,
                destinationAccountId: accountId,
                amount: adjustedAmount
            )
        } else {
            if asset.isNative {
                operation = try stellarKit.createAccountOperation(
                    destinationAccountId: accountId,
                    amount: adjustedAmount
                )
            } else {
                throw TransactionError.noTrustline
            }
        }

        return PaymentResult(
            operations: [operation],
            fee: baseFee,
            adjustedAmount: adjustedAmount
        )
    }

    static func send(
        operations: [stellarsdk.Operation],
        memo: Memo,
        keyPair: KeyPair
    ) async throws -> String {
        try await StellarKit.Kit.send(
            operations: operations,
            memo: memo,
            keyPair: keyPair,
        )
    }
    
    static func send(
        transactionData: TransactionData,
        token: Token,
        keyPair: KeyPair
    ) async throws {
        switch transactionData {
        case let .envelope(envelope):
            _ = try await StellarKit.Kit.send(
                transactionEnvelope: envelope,
                keyPair: keyPair,
            )
            
        case let .payment(asset, amount, accountId, memo):
            guard let stellarKit = Core.shared.stellarKitManager.stellarKit else {
                throw SendError.noStellarKit
            }
            
            let result = try await preparePayment(
                asset: asset,
                amount: amount,
                accountId: accountId,
                stellarKit: stellarKit
            )
            
            let memoObject = memo.map { Memo.text($0) } ?? Memo.none
            
            _ = try await send(
                operations: result.operations,
                memo: memoObject,
                keyPair: keyPair
            )
        }
    }
}

// UI Part

extension StellarSendHelper {
    static func caution(transactionError: Error, feeToken: Token) -> CautionNew {
        let title: String
        let text: String

        if let stellarError = transactionError as? TransactionError {
            switch stellarError {
            case let .insufficientStellarBalance(balance):
                let appValue = AppValue(token: feeToken, value: balance)
                let balanceString = appValue.formattedShort()

                title = "fee_settings.errors.insufficient_balance".localized
                text = "fee_settings.errors.insufficient_balance.info".localized(balanceString ?? "")
            case .noTrustline:
                title = "send.stellar.no_trustline.title".localized
                text = "send.stellar.no_trustline.description".localized
            }
        } else {
            title = "ethereum_transaction.error.title".localized
            text = transactionError.convertedError.smartDescription
        }

        return CautionNew(title: title, text: text, type: .error)
    }

    static func feeFields(
        fee: Decimal?,
        feeToken: Token,
        currency: Currency,
        feeTokenRate: Decimal?
    ) -> [SendField] {
        var viewItems = [SendField]()

        if let fee {
            let appValue = AppValue(token: feeToken, value: fee)
            let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: fee * $0) }

            viewItems.append(
                .value(
                    title: SendField.InformedTitle("fee_settings.network_fee".localized, info: .fee),
                    appValue: appValue,
                    currencyValue: currencyValue,
                    formatFull: true
                )
            )
        }

        return viewItems
    }
}

extension StellarSendHelper {
    enum TransactionData {
        case envelope(String)
        case payment(asset: StellarKit.Asset, amount: Decimal, accountId: String, memo: String?)
    }
    
    struct PaymentResult {
        let operations: [stellarsdk.Operation]
        let fee: Decimal
        let adjustedAmount: Decimal
    }

    enum SendError: Error {
        case noStellarKit
    }

    enum TransactionError: Error {
        case insufficientStellarBalance(balance: Decimal)
        case noTrustline
    }
}

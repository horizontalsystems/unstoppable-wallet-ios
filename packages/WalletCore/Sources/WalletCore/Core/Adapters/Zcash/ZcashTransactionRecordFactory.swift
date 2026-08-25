import Foundation
import MarketKit
import ZcashLightClientKit

class ZcashTransactionRecordFactory {
    private let token: Token
    private let transactionSource: TransactionSource
    private let migrator: ZcashMigrator

    weak var syncService: ZcashSyncService?

    init(token: Token, transactionSource: TransactionSource, migrator: ZcashMigrator) {
        self.token = token
        self.transactionSource = transactionSource
        self.migrator = migrator
    }

    private func isOwner(address: String?) -> Bool {
        if let uAddress = syncService?.uAddress {
            if uAddress.stringEncoded.lowercased() == address?.lowercased() {
                return true
            }
        }
        if let tAddress = syncService?.tAddress {
            if tAddress.stringEncoded.lowercased() == address?.lowercased() {
                return true
            }
        }
        return false
    }

    func transactionRecord(fromTransaction transaction: ZcashTransactionWrapper) -> TransactionRecord {
        let showRawTransaction = transaction.minedHeight == nil || transaction.failed

        // a migration tx is an internal fully-shielded self-send: without the txId match
        // it would fall into the internal branch below and display as Unshield
        if migrator.isMigrationTx(hash: transaction.transactionHash) {
            // the SDK records the migration PCZT without recipients, so the wrapper's internal-branch
            // math (value = received, fee = spent − received) never triggers; raw tx.value is just −fee
            let migratedAmount: Decimal
            let migrationFee: Decimal?
            if let spent = transaction.totalSpent, let received = transaction.totalReceived, received > .zero {
                migratedAmount = received.decimalValue.decimalValue
                migrationFee = (spent - received).decimalValue.decimalValue
            } else {
                migratedAmount = abs(transaction.value.decimalValue.decimalValue)
                migrationFee = transaction.fee?.decimalValue.decimalValue
            }

            return ZcashShieldingTransactionRecord(
                token: token,
                source: transactionSource,
                uid: transaction.transactionHash,
                transactionHash: transaction.transactionHash,
                transactionIndex: transaction.transactionIndex,
                blockHeight: transaction.minedHeight,
                confirmationsThreshold: ZcashSDK.defaultRewindDistance,
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                fee: migrationFee,
                failed: transaction.failed,
                lockInfo: nil,
                conflictingHash: nil,
                showRawTransaction: showRawTransaction,
                amount: migratedAmount,
                direction: .migrate,
                memo: transaction.memo
            )
        }

        // TODO: Should have it's own transactions with memo
        if let direction = transaction.shieldDirection {
            return ZcashShieldingTransactionRecord(
                token: token,
                source: transactionSource,
                uid: transaction.transactionHash,
                transactionHash: transaction.transactionHash,
                transactionIndex: transaction.transactionIndex,
                blockHeight: transaction.minedHeight,
                confirmationsThreshold: ZcashSDK.defaultRewindDistance,
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                fee: transaction.fee?.decimalValue.decimalValue,
                failed: transaction.failed,
                lockInfo: nil,
                conflictingHash: nil,
                showRawTransaction: showRawTransaction,
                amount: abs(transaction.value.decimalValue.decimalValue),
                direction: .init(direction: direction),
                memo: transaction.memo
            )
        }
        if !transaction.isSentTransaction {
            let isOwner = isOwner(address: transaction.recipientAddress)
            return BitcoinIncomingTransactionRecord(
                token: token,
                source: transactionSource,
                uid: transaction.transactionHash,
                transactionHash: transaction.transactionHash,
                transactionIndex: transaction.transactionIndex,
                blockHeight: transaction.minedHeight,
                confirmationsThreshold: ZcashSDK.defaultRewindDistance,
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                fee: transaction.fee?.decimalValue.decimalValue,
                failed: transaction.failed,
                lockInfo: nil,
                conflictingHash: nil,
                showRawTransaction: showRawTransaction,
                amount: abs(transaction.value.decimalValue.decimalValue),
                from: isOwner ? nil : transaction.recipientAddress,
                to: isOwner ? transaction.recipientAddress : nil,
                memo: transaction.memo
            )
        } else {
            return ZcashOutgoingTransactionRecord(
                token: token,
                source: transactionSource,
                uid: transaction.transactionHash,
                transactionHash: transaction.transactionHash,
                transactionIndex: transaction.transactionIndex,
                blockHeight: transaction.minedHeight,
                confirmationsThreshold: ZcashSDK.defaultRewindDistance,
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                fee: transaction.fee?.decimalValue.decimalValue,
                failed: transaction.failed,
                lockInfo: nil,
                conflictingHash: nil,
                showRawTransaction: showRawTransaction,
                amount: abs(transaction.value.decimalValue.decimalValue),
                to: transaction.recipientAddress,
                sentToSelf: false,
                memo: transaction.memo,
                replaceable: false,
                recipients: transaction.recipients,
                isShielding: transaction.shieldDirection != nil
            )
        }
    }
}

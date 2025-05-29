import Foundation
import HsExtensions
import ZcashLightClientKit

class ZcashTransactionWrapper {
    let raw: Data?
    let transactionHash: String
    let transactionIndex: Int
    let recipients: [TransactionRecipient]
    let isSentTransaction: Bool
    let shieldDirection: Direction?
    let expiryHeight: Int?
    let minedHeight: Int?
    let timestamp: TimeInterval
    let value: Zatoshi
    let totalSpent: Zatoshi?
    let totalReceived: Zatoshi?
    let fee: Zatoshi?
    let memo: String?
    let failed: Bool

    var recipientAddress: String? {
        recipients
            .filter(\.hasAddress)
            .first?
            .address
    }

    init?(accountId: AccountUUID, tx: ZcashTransaction.Overview, memo: String?, recipients: [TransactionRecipient], lastBlockHeight: Int) {
//        ZcashTransactionWrapper.printTransaction(tx: tx, recipients: recipients)

        raw = tx.raw
        transactionHash = tx.rawID.hs.reversedHex
        transactionIndex = tx.index ?? 0
        self.recipients = recipients
        isSentTransaction = tx.isSentTransaction
        minedHeight = tx.minedHeight
        expiryHeight = tx.expiryHeight
        failed = tx.getState(for: lastBlockHeight) == .expired
        timestamp = failed ? 0 : (tx.blockTime ?? Date().timeIntervalSince1970) // need this to update pending transactions and shows on transaction tab
        totalSpent = tx.totalSpent
        totalReceived = tx.totalReceived

        // if sent tx with all recipients same to accountId and spent&received > 0, it means that we receive money inside account(from shield to unshield or vice versa)
        let hasSpentAndReceived = ((tx.totalSpent ?? .zero) > .zero) && ((tx.totalReceived ?? .zero) > .zero)
        let internalTransaction =
            hasSpentAndReceived &&
            recipients.count > 0 &&
            tx.isSentTransaction && recipients.allSatisfy { recipient in
                if case let .internalAccount(accountUUID) = recipient {
                    return accountUUID == accountId
                }
                return false
            }

        // if shield or only internal(expect unshield)
        if tx.isShielding || internalTransaction {
            shieldDirection = tx.isShielding ? .shield : .unshield

            if let spent = tx.totalSpent, let received = tx.totalReceived {
                fee = spent - received
                value = received
            } else {
                fee = tx.fee
                value = tx.value
            }
        } else {
            shieldDirection = nil
            fee = tx.fee
            value = tx.value
        }

        self.memo = memo
    }

    static func printTransaction(tx: ZcashTransaction.Overview, recipients: [TransactionRecipient]) {
        print("========== TRANSACTION =============")
        print("= acc: \(tx.accountUUID.encodedString)")
        print("= index: \(tx.index ?? -1)")
        print("= id: \(tx.rawID.hs.reversedHex)")
        print("= raw: \(tx.raw.encodedString.prefix(20))...")
        print("= time: \(Date(timeIntervalSince1970: tx.blockTime ?? 0))")
        print("= memoCount: \(tx.memoCount)")
        print("= sentNoteCount: \(tx.sentNoteCount)")
        print("= receivedNoteCount: \(tx.receivedNoteCount)")
        print("= isExpiredUmined: \(tx.isExpiredUmined?.description ?? "N/A")")
        print("-------------------------------------")
        print("= value: \((tx.value).decimalValue.decimalValue)")
        print("= isSent: \(tx.isSentTransaction)")
        print("= isShielding: \(tx.isShielding)")
        print("= hasChange: \(tx.hasChange)")
        print("= total Spent: \((tx.totalSpent ?? .zero).decimalValue.decimalValue)")
        print("= total Received: \((tx.totalReceived ?? .zero).decimalValue.decimalValue)")
        print("= total Received: \((tx.totalReceived ?? .zero).decimalValue.decimalValue)")
        print("= fee: \((tx.fee ?? .zero).decimalValue.decimalValue)")
        print("-----------Recipients----------------")
        for recipient in recipients {
            switch recipient {
            case let .address(recipient): print("- Address: \(recipient.stringEncoded)")
            case let .internalAccount(accountId): print("- InternalAcc: \(accountId.encodedString)")
            }
        }
        print("=====================================")
    }
}

extension ZcashTransactionWrapper: Comparable {
    public static func < (lhs: ZcashTransactionWrapper, rhs: ZcashTransactionWrapper) -> Bool {
        if lhs.timestamp != rhs.timestamp {
            return lhs.timestamp > rhs.timestamp
        } else {
            return lhs.transactionIndex > rhs.transactionIndex
        }
    }

    public static func == (lhs: ZcashTransactionWrapper, rhs: ZcashTransactionWrapper) -> Bool {
        lhs.transactionHash == rhs.transactionHash
    }
}

extension ZcashTransactionWrapper: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(transactionHash)
    }
}

extension ZcashTransactionWrapper {
    enum Direction {
        case shield, unshield
    }

    var description: String {
        "TX(Zcash) === hash:\(transactionHash) : \(recipientAddress?.prefix(6) ?? "N/A") : \(transactionIndex) height: \(minedHeight?.description ?? "N/A") timestamp \(timestamp.description)"
    }
}

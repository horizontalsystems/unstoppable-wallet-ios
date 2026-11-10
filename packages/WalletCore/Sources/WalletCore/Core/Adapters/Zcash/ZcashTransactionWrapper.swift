import Foundation
import HsExtensions
import ZODLSwiftWalletSDK

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
    /// A ZIP 318 (Orchard to Ironwood) migration transaction, as the SDK classifies it from the transaction itself
    let isMigration: Bool
    /// The value a migration transfer moved across pools; nil for any other transaction
    let poolCrossingValue: Zatoshi?

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
        let sdkState = tx.getState(for: lastBlockHeight)
        failed = sdkState == .expired
        // RESEARCH SHIM: upstream Overview has no createdAt (HS delta, replayed in step 3).
        timestamp = tx.blockTime ?? Date().timeIntervalSince1970
        totalSpent = tx.totalSpent
        totalReceived = tx.totalReceived

        isMigration = Self.isMigration(kind: tx.zip318Kind)
        poolCrossingValue = tx.poolCrossingValue

        let recipientsAllInternal = !recipients.isEmpty && recipients.allSatisfy { recipient in
            if case let .internalAccount(accountUUID) = recipient {
                return accountUUID == accountId
            }
            return false
        }
        let internalTransaction = Self.isInternalTransfer(
            isSentTransaction: tx.isSentTransaction,
            value: tx.value,
            fee: tx.fee,
            totalSpent: tx.totalSpent,
            totalReceived: tx.totalReceived,
            recipientsAllInternal: recipientsAllInternal
        )

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
    static func < (lhs: ZcashTransactionWrapper, rhs: ZcashTransactionWrapper) -> Bool {
        guard lhs.timestamp == rhs.timestamp else {
            return lhs.timestamp > rhs.timestamp
        }
        guard lhs.transactionIndex == rhs.transactionIndex else {
            return lhs.transactionIndex > rhs.transactionIndex
        }

        return lhs.transactionHash > rhs.transactionHash
    }

    static func == (lhs: ZcashTransactionWrapper, rhs: ZcashTransactionWrapper) -> Bool {
        lhs.transactionHash == rhs.transactionHash
    }
}

extension ZcashTransactionWrapper: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(transactionHash)
    }
}

extension ZcashTransactionWrapper {
    enum Direction {
        case shield, unshield
    }

    /// Only `preparation` and `transfer` are a migration; `notClassified` is the absence of a decision, not a "no"
    static func isMigration(kind: ZcashTransaction.Overview.ZIP318Kind) -> Bool {
        switch kind {
        case .preparation, .transfer: return true
        default: return false
        }
    }

    /// A move between the account's own pools costs it exactly the fee. A payment out costs more, so a payment made on
    /// another device — whose external recipient this wallet may not have decrypted yet, leaving only the change in
    /// sight — stays a payment instead of turning into an unshield whose "fee" is the whole payment.
    static func isInternalTransfer(
        isSentTransaction: Bool,
        value: Zatoshi,
        fee: Zatoshi?,
        totalSpent: Zatoshi?,
        totalReceived: Zatoshi?,
        recipientsAllInternal: Bool
    ) -> Bool {
        guard isSentTransaction, recipientsAllInternal, let fee,
              (totalSpent ?? .zero) > .zero, (totalReceived ?? .zero) > .zero
        else {
            return false
        }

        return value == Zatoshi(-fee.amount)
    }

    var description: String {
        "TX(Zcash) === hash:\(transactionHash) : \(recipientAddress?.prefix(6) ?? "N/A") : \(transactionIndex) height: \(minedHeight?.description ?? "N/A") timestamp \(timestamp.description)"
    }
}

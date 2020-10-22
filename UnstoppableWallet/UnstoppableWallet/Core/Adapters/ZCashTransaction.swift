import ZcashLightClientKit

class ZCashTransaction {
    let id: String?
    let transactionHash: String
    let transactionIndex: Int
    let toAddress: String?
    let expiryHeight: Int?
    let minedHeight: Int?
    let timestamp: TimeInterval
    let value: Int
    let memo: String?
    let failed: Bool

    init?(confirmedTransaction: ConfirmedTransactionEntity) {
        print("mapping confirmed into zCash")
        guard let rawTransactionId = confirmedTransaction.rawTransactionId else {
            print("rawTxID = nil!")
            return nil
        }

        id = confirmedTransaction.id?.description
        transactionHash = rawTransactionId.hex
        transactionIndex = confirmedTransaction.transactionIndex
        toAddress = confirmedTransaction.toAddress
        minedHeight = confirmedTransaction.minedHeight
        expiryHeight = confirmedTransaction.expiryHeight
        timestamp = confirmedTransaction.blockTimeInSeconds
        value = confirmedTransaction.value
        memo = confirmedTransaction.memo.flatMap { String(bytes: $0, encoding: .utf8) }
        failed = false
    }

    init?(pendingTransaction: PendingTransactionEntity) {
        guard let rawTransactionId = pendingTransaction.rawTransactionId else {
            return nil
        }

        id = pendingTransaction.id?.description
        transactionHash = rawTransactionId.hex
        transactionIndex = -1
        toAddress = pendingTransaction.toAddress
        minedHeight = nil
        expiryHeight = pendingTransaction.expiryHeight
        timestamp = pendingTransaction.createTime
        value = pendingTransaction.value
        memo = pendingTransaction.memo.flatMap { String(bytes: $0, encoding: .utf8) }
        failed = pendingTransaction.isFailure
    }

}

extension ZCashTransaction: Comparable {

    public static func <(lhs: ZCashTransaction, rhs: ZCashTransaction) -> Bool {
        if lhs.timestamp != rhs.timestamp {
            return lhs.timestamp > rhs.timestamp
        } else {
            return lhs.transactionIndex > rhs.transactionIndex
        }
    }

    public static func ==(lhs: ZCashTransaction, rhs: ZCashTransaction) -> Bool {
        lhs.transactionHash == rhs.transactionHash
    }

}

extension ZCashTransaction: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(transactionHash)
    }

}

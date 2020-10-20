import ZcashLightClientKit

class ZCashTransaction {
    let id: String?
    let transactionHash: String?
    let transactionIndex: Int
    let toAddress: String?
    let expiryHeight: Int?
    let minedHeight: Int?
    let timestamp: TimeInterval
    let value: Int
    let memo: String?

    init(confirmedTransaction: ConfirmedTransactionEntity) {
        id = confirmedTransaction.id?.description
        transactionHash = confirmedTransaction.rawTransactionId?.hex
        transactionIndex = confirmedTransaction.transactionIndex
        toAddress = confirmedTransaction.toAddress
        minedHeight = confirmedTransaction.minedHeight
        expiryHeight = confirmedTransaction.expiryHeight
        timestamp = confirmedTransaction.blockTimeInSeconds
        value = confirmedTransaction.value
        memo = confirmedTransaction.memo.flatMap { String(bytes: $0, encoding: .utf8) }
    }

    init(pendingTransaction: PendingTransactionEntity) {
        id = pendingTransaction.id?.description
        transactionHash = pendingTransaction.rawTransactionId?.hex
        transactionIndex = -1
        toAddress = pendingTransaction.toAddress
        minedHeight = nil
        expiryHeight = pendingTransaction.expiryHeight
        timestamp = pendingTransaction.createTime
        value = pendingTransaction.value
        memo = pendingTransaction.memo.flatMap { String(bytes: $0, encoding: .utf8) }
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
        lhs.transactionHash == rhs.transactionHash &&
        lhs.timestamp == rhs.timestamp &&
        lhs.transactionIndex == rhs.transactionIndex
    }

}

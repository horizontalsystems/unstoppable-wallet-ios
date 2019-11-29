import Foundation

struct TransactionRecord {
    let uid: String
    let transactionHash: String
    let transactionIndex: Int
    let interTransactionIndex: Int
    let blockHeight: Int?
    let amount: Decimal
    let fee: Decimal?
    let date: Date
    let failed: Bool

    let from: [TransactionAddress]
    let to: [TransactionAddress]
}

struct TransactionAddress {
    let address: String
    let mine: Bool
    let pluginId: UInt8?
    let pluginData: Any?

    init(address: String, mine: Bool, pluginId: UInt8? = nil, pluginData: Any? = nil) {
        self.address = address
        self.mine = mine
        self.pluginId = pluginId
        self.pluginData = pluginData
    }

}

extension TransactionRecord: Comparable {

    public static func <(lhs: TransactionRecord, rhs: TransactionRecord) -> Bool {
        guard lhs.date == rhs.date else {
            return lhs.date < rhs.date
        }

        guard lhs.transactionIndex == rhs.transactionIndex else {
            return lhs.transactionIndex < rhs.transactionIndex
        }

        return lhs.interTransactionIndex < rhs.interTransactionIndex
    }

    public static func ==(lhs: TransactionRecord, rhs: TransactionRecord) -> Bool {
        lhs.uid == rhs.uid
    }

}

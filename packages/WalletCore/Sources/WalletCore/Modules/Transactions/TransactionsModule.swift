import MarketKit

struct TransactionItem: Comparable {
    var record: TransactionRecord
    var status: TransactionStatus
    var lockState: TransactionLockState?

    static func < (lhs: TransactionItem, rhs: TransactionItem) -> Bool {
        lhs.record < rhs.record
    }

    static func == (lhs: TransactionItem, rhs: TransactionItem) -> Bool {
        lhs.record == rhs.record
    }
}

public struct TransactionFilter: Equatable {
    private(set) var blockchain: Blockchain?
    private(set) var token: Token?
    var contact: Contact?

    public init() {
        blockchain = nil
        token = nil
        contact = nil
    }

    public init(token: Token) {
        blockchain = token.blockchain
        self.token = token
        contact = nil
    }

    var hasChanges: Bool {
        blockchain != nil || token != nil || contact != nil
    }

    private mutating func updateContact() {
        guard let blockchain, let contact else {
            return
        }

        // reset contact if selected blockchain not allowed for search by contact
        guard TransactionContactSelectViewModel.allowedBlockchainUids.contains(blockchain.type.uid) else {
            self.contact = nil
            return
        }

        // reset contact if it's doesnt have address for selected blockchain
        guard contact.has(blockchainUId: blockchain.uid) else {
            self.contact = nil
            return
        }
    }

    mutating func set(blockchain: Blockchain?) {
        self.blockchain = blockchain
        token = nil

        updateContact()
    }

    mutating func set(token: Token?) {
        self.token = token
        blockchain = token?.blockchain

        updateContact()
    }

    mutating func reset() {
        blockchain = nil
        token = nil
        contact = nil
    }
}

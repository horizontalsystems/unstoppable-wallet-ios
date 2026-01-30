import MarketKit

class SpamEvaluationContext {
    let transaction: SpamTransactionInfo

    // Shared storage for conditions to pass data to each other
    private var storage: [String: Any] = [:]

    init(transaction: SpamTransactionInfo) {
        self.transaction = transaction
    }

    func set(_ key: String, value: Any) {
        storage[key] = value
    }

    func get<T>(_ key: String) -> T? {
        storage[key] as? T
    }

    func contains(_ key: String) -> Bool {
        storage[key] != nil
    }
}

enum SpamContextKeys {
    static let matchedAddress = "matched_address"
    static let matchedTimestamp = "matched_timestamp"
    static let matchedBlockHeight = "matched_block_height"
}

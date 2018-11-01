import RealmSwift

class TransactionRecord: Object {
    @objc dynamic var transactionHash: String = ""
    @objc dynamic var blockHeight: Int = 0
    @objc dynamic var coin: String = ""
    @objc dynamic var amount: Double = 0
    @objc dynamic var timestamp: Int = 0
    @objc dynamic var rate: Double = 0

    let from = List<TransactionAddress>()
    let to = List<TransactionAddress>()

    override class func primaryKey() -> String? {
        return "transactionHash"
    }
}

class TransactionAddress: Object {
    @objc dynamic var address: String = ""
    @objc dynamic var mine: Bool = false
}

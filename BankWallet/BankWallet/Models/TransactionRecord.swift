import RealmSwift

@objc enum TransactionStatus: Int {
    case processing
    case verifying
    case completed
}

class TransactionRecord: Object {
    @objc dynamic var transactionHash: String = ""
    @objc dynamic var coin: String = ""
    @objc dynamic var amount: Double = 0
    @objc dynamic var status: TransactionStatus = .processing
    @objc dynamic var verifyProgress: Double = 0
    @objc dynamic var timestamp: Double = 0
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

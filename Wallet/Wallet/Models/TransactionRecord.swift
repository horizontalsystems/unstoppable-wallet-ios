import Foundation
import RealmSwift

class TransactionRecord: Object {
    @objc dynamic var transactionHash: String = ""
    @objc dynamic var coinCode: String = ""
    @objc dynamic var from: String = ""
    @objc dynamic var to: String = ""
    @objc dynamic var amount: Int = 0
    @objc dynamic var fee: Int = 0
    @objc dynamic var incoming: Bool = true
    @objc dynamic var blockHeight: Int = 0
    @objc dynamic var timestamp: Int = 0
    @objc dynamic var confirmed: Bool = false

    override class func primaryKey() -> String? {
        return "transactionHash"
    }

}

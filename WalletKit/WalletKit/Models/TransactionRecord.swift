import Foundation
import RealmSwift

public class TransactionRecord: Object {
    @objc public dynamic var transactionHash: String = ""
    @objc public dynamic var coinCode: String = ""
    @objc public dynamic var from: String = ""
    @objc public dynamic var to: String = ""
    @objc public dynamic var amount: Int = 0
    @objc public dynamic var fee: Int = 0
    @objc public dynamic var incoming: Bool = true
    @objc public dynamic var blockHeight: Int = 0
    @objc public dynamic var timestamp: Int = 0

    override public class func primaryKey() -> String? {
        return "transactionHash"
    }

}

import Foundation
import RealmSwift

public class Transaction: Object {
    @objc public dynamic var transactionHash: String = ""
    @objc public dynamic var block: Block?

    override public class func primaryKey() -> String? {
        return "transactionHash"
    }

}

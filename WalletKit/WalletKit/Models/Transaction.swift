import Foundation
import RealmSwift

public class Transaction: Object {
    @objc public dynamic var reversedHashHex: String = ""
    @objc public dynamic var block: Block?

    override public class func primaryKey() -> String? {
        return "reversedHashHex"
    }

}

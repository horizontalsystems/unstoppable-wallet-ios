import Foundation
import RealmSwift

public class Balance: Object {
    @objc public dynamic var coinCode: String = ""
    @objc public dynamic var amount: Double = 0

    override public class func primaryKey() -> String? {
        return "coinCode"
    }

}

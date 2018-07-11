import Foundation
import RealmSwift

public class ExchangeRate: Object {
    @objc public dynamic var code: String = ""
    @objc public dynamic var value: Double = 0

    override public class func primaryKey() -> String? {
        return "code"
    }

}

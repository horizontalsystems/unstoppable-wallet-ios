import Foundation
import RealmSwift

class Balance: Object {
    @objc dynamic var coinCode: String = ""
    @objc dynamic var amount: Double = 0

    override class func primaryKey() -> String? {
        return "coinCode"
    }

}

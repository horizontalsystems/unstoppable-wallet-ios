import Foundation
import RealmSwift

class ExchangeRate: Object {
    @objc dynamic var code: String = ""
    @objc dynamic var value: Double = 0

    override class func primaryKey() -> String? {
        return "code"
    }

}

import Foundation
import RealmSwift

public class TransactionInput: Object {
    @objc public dynamic var address = ""
    @objc public dynamic var value: Int = 0
}

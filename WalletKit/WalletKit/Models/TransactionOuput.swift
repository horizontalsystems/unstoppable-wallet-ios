import Foundation
import RealmSwift

public class TransactionOuput: Object {
    @objc public dynamic var address = ""
    @objc public dynamic var value: Int = 0
    @objc public dynamic var mine = false
}

import Foundation
import RealmSwift

class BlockchainInfo: Object {

    @objc dynamic var coinCode: String = ""
    @objc dynamic var latestBlockHeight: Int = 0

    override class func primaryKey() -> String? {
        return "coinCode"
    }

}

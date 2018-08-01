import Foundation
import RealmSwift

public class Block: Object {
    @objc public dynamic var reversedHeaderHashHex = ""
    @objc public dynamic var headerHash = Data()
    @objc public dynamic var height: Int = 0
    @objc public dynamic var synced = false

    @objc public dynamic var header: BlockHeader!
    @objc public dynamic var previousBlock: Block?

    let transactions = LinkingObjects(fromType: Transaction.self, property: "block")

    override public class func primaryKey() -> String? {
        return "reversedHeaderHashHex"
    }

}

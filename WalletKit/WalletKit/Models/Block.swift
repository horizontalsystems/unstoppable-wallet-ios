import Foundation
import RealmSwift

public class Block: Object {
    @objc public dynamic var reversedHeaderHashHex = ""
    @objc public dynamic var headerHash = Data()
    @objc public dynamic var rawHeader = Data()
    @objc public dynamic var height: Int = 0
    @objc public dynamic var archived = false
    let transactions = LinkingObjects(fromType: Transaction.self, property: "block")

    convenience init(blockHeader: BlockHeaderItem, height: Int, archived: Bool = false) {
        self.init()

        rawHeader = blockHeader.serialized()
        headerHash = Crypto.sha256sha256(rawHeader)
        reversedHeaderHashHex = headerHash.reversedHex
        self.height = height
        self.archived = archived
    }

    override public class func primaryKey() -> String? {
        return "reversedHeaderHashHex"
    }
}

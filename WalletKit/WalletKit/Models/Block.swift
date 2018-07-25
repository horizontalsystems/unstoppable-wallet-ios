import Foundation
import RealmSwift

public class Block: Object {
    @objc public dynamic var reversedHeaderHashHex = ""
    @objc public dynamic var headerHash = Data()
    @objc public dynamic var rawHeader = Data()
    @objc public dynamic var height: Int = 0
    @objc public dynamic var synced = false

    let transactions = LinkingObjects(fromType: Transaction.self, property: "block")
    @objc public dynamic var previousBlock: Block?

    convenience init(blockHeader: BlockHeaderItem, previousBlock: Block? = nil, height: Int? = nil) {
        self.init()

        rawHeader = blockHeader.serialized()
        headerHash = Crypto.sha256sha256(rawHeader)
        reversedHeaderHashHex = headerHash.reversedHex
        self.previousBlock = previousBlock

        if let previousHeight = previousBlock?.height {
            self.height = previousHeight + 1
        } else if let height = height {
            self.height = height
        }
    }

    override public class func primaryKey() -> String? {
        return "reversedHeaderHashHex"
    }
}

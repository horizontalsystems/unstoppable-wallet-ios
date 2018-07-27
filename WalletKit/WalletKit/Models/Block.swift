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

    convenience init(header: BlockHeader, previousBlock: Block) {
        self.init(header: header)

        height = previousBlock.height + 1
        self.previousBlock = previousBlock
    }

    convenience init(header: BlockHeader, height: Int) {
        self.init(header: header)

        self.height = height
    }

    private convenience init(header: BlockHeader) {
        self.init()

        headerHash = Crypto.sha256sha256(header.serialized())
        reversedHeaderHashHex = headerHash.reversedHex
        self.header = header
    }

    override public class func primaryKey() -> String? {
        return "reversedHeaderHashHex"
    }

}

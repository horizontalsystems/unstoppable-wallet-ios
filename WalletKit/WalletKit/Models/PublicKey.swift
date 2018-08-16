import Foundation
import RealmSwift

public class PublicKey: Object {

    enum InitError: Error {
        case invalid
        case wrongNetwork
    }

    let outputs = LinkingObjects(fromType: TransactionOutput.self, property: "publicKey")

    @objc dynamic var index = 0
    @objc dynamic var external = true
    @objc dynamic var raw: Data?
    @objc dynamic var keyHash = Data()
    @objc public dynamic var address = ""

    convenience init(withIndex index: Int, external: Bool, hdPublicKey key: HDPublicKey) {
        self.init()
        self.index = index
        self.external = external
        self.raw = key.raw
        self.keyHash = Crypto.sha256ripemd160(key.raw)
        self.address = key.toAddress()
    }

    override public class func primaryKey() -> String? {
        return "address"
    }

}

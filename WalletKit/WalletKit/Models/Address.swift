import Foundation
import RealmSwift

class Address: Object {

    enum InitError: Error {
        case invalid
        case wrongNetwork
    }

    @objc dynamic var index = 0
    @objc dynamic var external = true
    @objc dynamic var publicKey: Data?
    @objc dynamic var publicKeyHash = Data()
    @objc dynamic var base58 = ""

    convenience init(withIndex index: Int, external: Bool, hdPublicKey key: HDPublicKey) {
        self.init()
        self.index = index
        self.external = external
        self.publicKey = key.raw
        self.publicKeyHash = Crypto.sha256ripemd160(key.raw)
        self.base58 = key.toAddress()
    }

    override class func primaryKey() -> String? {
        return "base58"
    }

}

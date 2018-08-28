import Realm
import RealmSwift
import Foundation

class AddressManager {

    private let realmFactory: RealmFactory
    private let hdWallet: HDWallet

    init(realmFactory: RealmFactory, hdWallet: HDWallet) {
        self.realmFactory = realmFactory
        self.hdWallet = hdWallet
    }

    func changePublicKey() throws -> PublicKey {
        return try getPublicKey(chain: .internal)
    }

    func receiveAddress() throws -> String {
        return try getPublicKey(chain: .external).address
    }

    func generateKeys() throws {
        let realm = realmFactory.realm
        let externalKeys = try generateKeys(external: true, realm: realm)
        let internalKeys = try generateKeys(external: false, realm: realm)

        try realm.write {
            realm.add(externalKeys)
            realm.add(internalKeys)
        }
    }

    private func generateKeys(external: Bool, realm: Realm) throws -> [PublicKey] {
        var keys = [PublicKey]()
        let existingKeys = realm.objects(PublicKey.self).filter("external = %@ AND outputs.@count = 0", external).sorted(byKeyPath: "index")

        if existingKeys.count < hdWallet.gapLimit {
            let lastIndex = existingKeys.last?.index ?? -1

            for i in 1..<(hdWallet.gapLimit - existingKeys.count + 1) {
                let newPublicKey = try external ? hdWallet.receivePublicKey(index: lastIndex + i) : hdWallet.changePublicKey(index: lastIndex + i)
                keys.append(newPublicKey)
            }
        }

        return keys
    }

    private func getPublicKey(chain: HDWallet.Chain) throws -> PublicKey {
        let realm = realmFactory.realm
        let existingKeys = realm.objects(PublicKey.self).filter("external = %@", chain == .external).sorted(byKeyPath: "index")

        for key in existingKeys {
            if key.outputs.count == 0 {
                return key
            }
        }

        let newIndex = (existingKeys.last?.index ?? -1) + 1
        let newPublicKey = try chain == .external ? hdWallet.receivePublicKey(index: newIndex) : hdWallet.changePublicKey(index: newIndex)

        try realm.write {
            realm.add(newPublicKey)
        }

        return newPublicKey
    }

}

import Foundation
import RealmSwift

class RealmFactory {
    static let shared = RealmFactory()

    var realm: Realm {
        return try! Realm(configuration: WalletKitManager.shared.realmConfiguration)
    }

}

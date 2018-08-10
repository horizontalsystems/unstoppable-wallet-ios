import Foundation
import RealmSwift

class RealmFactory {

    var realm: Realm {
        return try! Realm(configuration: WalletKitManager.shared.realmConfiguration)
    }

}

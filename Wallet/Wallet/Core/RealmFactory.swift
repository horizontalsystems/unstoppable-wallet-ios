import Foundation
import RealmSwift

class RealmFactory {
    static let instance = RealmFactory()

    private init() {
    }

    func createWalletRealm() -> Realm {
        let config = SyncUser.current!.configuration(realmURL: URL(string: "realms://grouvi-wallet.us1a.cloud.realm.io/default")!)
        let realm = try! Realm(configuration: config)

//        _ = realm.objects(UnspentOutput.self).subscribe(named: "unspent-outputs")
//        _ = realm.objects(ExchangeRate.self).subscribe(named: "exchange-rates")

        return realm
    }

    func login(onCompletion completion: @escaping UserCompletionBlock) {
        let authURL = URL(string: "https://grouvi-wallet.us1a.cloud.realm.io")!
        let credentials = SyncCredentials.usernamePassword(username: "ermat", password: "123")

        SyncUser.logIn(with: credentials, server: authURL, onCompletion: completion)
    }

}

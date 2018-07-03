import Foundation
import RealmSwift
import RxSwift
import RxRealm

class RealmManager {

    func createWalletRealm() -> Realm {
        let config = SyncUser.current!.configuration(realmURL: URL(string: "realms://grouvi-wallet.us1a.cloud.realm.io/~/wallet")!)
        let realm = try! Realm(configuration: config)

        _ = realm.objects(BitcoinUnspentOutput.self).subscribe(named: "bitcoin-unspent-outputs")
        _ = realm.objects(BitcoinCashUnspentOutput.self).subscribe(named: "bitcoin-cash-unspent-outputs")
        _ = realm.objects(ExchangeRate.self).subscribe(named: "exchange-rates")
        _ = realm.objects(TransactionRecord.self).subscribe(named: "transaction-records")
        _ = realm.objects(BlockchainInfo.self).subscribe(named: "blockchain-infos")

        return realm
    }

    func login(withJwtToken token: String) -> Observable<Void> {
        return Observable.create { observer in
            let authURL = URL(string: "https://grouvi-wallet.us1a.cloud.realm.io")!
            let credentials = SyncCredentials.jwt(token)

            for (_, user) in SyncUser.all {
                print("Logging out: \(user.identity)")
                user.logOut()
            }

            SyncUser.logIn(with: credentials, server: authURL, onCompletion: { user, error in
                if user != nil {
                    observer.on(.completed)
                } else if let error = error {
                    observer.on(.error(error))
                }
            })

            return Disposables.create()
        }
    }

}

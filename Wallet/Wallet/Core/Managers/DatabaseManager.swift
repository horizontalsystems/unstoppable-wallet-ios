import Foundation
import RxSwift
import RealmSwift
import RxRealm

class DatabaseManager: IDatabaseManager {
    private let realm = RealmFactory.instance.createWalletRealm()

    func getUnspentOutputs() -> Observable<DatabaseChangeset<UnspentOutput>> {
        return Observable.arrayWithChangeset(from: realm.objects(UnspentOutput.self))
                .map { DatabaseChangeset(array: $0, changeset: $1) }
    }

    func getExchangeRates() -> Observable<DatabaseChangeset<ExchangeRate>> {
        return Observable.arrayWithChangeset(from: realm.objects(ExchangeRate.self))
                .map { DatabaseChangeset(array: $0, changeset: $1) }
    }

}

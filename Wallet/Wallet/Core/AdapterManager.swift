import Foundation
import RealmSwift
import RxSwift

class AdapterManager {
    static let shared = AdapterManager()

    var adapters = [IAdapter]()

    var subject = PublishSubject<Void>()

    func add(adapter: IAdapter) {
        var adapter = adapter
        adapter.listener = self
        adapters.append(adapter)
    }

}

extension AdapterManager: IAdapterListener {

    func handle(transactionRecords: [TransactionRecord]) {
        let realm = try! Realm()
        try? realm.write {
            realm.add(transactionRecords, update: true)
        }
    }

}

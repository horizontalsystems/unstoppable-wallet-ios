import Foundation
import RealmSwift

class AdapterManager {
    static let shared = AdapterManager()

    var adapters = [IAdapter]()

    func add(adapter: IAdapter) {
        var adapter = adapter
        adapter.listener = self
        adapters.append(adapter)
    }

}

extension AdapterManager: IAdapterListener {

    func updateBalance() {
    }

    func handle(transactionRecords: [TransactionRecord]) {
        let realm = try! Realm()
        try? realm.write {
            realm.add(transactionRecords, update: true)
        }
    }

}

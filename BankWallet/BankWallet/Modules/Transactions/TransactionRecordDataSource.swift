import RealmSwift

class TransactionRecordDataSource {
    weak var delegate: ITransactionRecordDataSourceDelegate?

    private let realmFactory: IRealmFactory

    var results: Results<TransactionRecord>
    var token: NotificationToken?

    init(realmFactory: IRealmFactory) {
        self.realmFactory = realmFactory

        results = TransactionRecordDataSource.results(realmFactory: realmFactory, coin: nil)
    }

    private func subscribe() {
        token?.invalidate()

        token = results.observe { [weak self] _ in
            self?.delegate?.onUpdateResults()
        }
    }

    deinit {
        token?.invalidate()
    }

    static func results(realmFactory: IRealmFactory, coin: Coin?) -> Results<TransactionRecord> {
        var results = realmFactory.realm.objects(TransactionRecord.self).sorted(byKeyPath: "timestamp", ascending: false)

        if let coin = coin {
            results = results.filter("coin = %@", coin)
        }

        return results
    }

}

extension TransactionRecordDataSource: ITransactionRecordDataSource {

    var count: Int {
        return results.count
    }

    func record(forIndex index: Int) -> TransactionRecord {
        return results[index]
    }

    func set(coin: Coin?) {
        results = TransactionRecordDataSource.results(realmFactory: realmFactory, coin: coin)
        subscribe()
    }

}

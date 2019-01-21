import RxSwift
import GRDB
import RxGRDB

class GrdbStorage {
    private let dbPool: DatabasePool

    init() {
        let databaseURL = try! FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("bank.sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try? migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createRate") { db in
            try db.create(table: "rate") { t in
                t.column("coinCode", .text).notNull()
                t.column("currencyCode", .text).notNull()
                t.column("value", .double).notNull()
                t.column("timestamp", .double).notNull()

                t.primaryKey(["coinCode", "currencyCode"], onConflict: .replace)
            }
        }
        migrator.registerMigration("createCoinsTable") { db in
            try db.create(table: StorableCoin.databaseTableName) { t in
                t.column(StorableCoin.Columns.title.name, .text).notNull()
                t.column(StorableCoin.Columns.code.name, .text).notNull()
                t.column(StorableCoin.Columns.type.name, .text).notNull()
                t.column(StorableCoin.Columns.enabled.name, .boolean).notNull()
                t.column(StorableCoin.Columns.coinOrder.name, .integer)

                t.primaryKey([StorableCoin.Columns.code.name, StorableCoin.Columns.type.name], onConflict: .replace)
            }
        }

        return migrator
    }

}

extension GrdbStorage: IRateStorage {

    func rateObservable(forCoinCode coinCode: CoinCode, currencyCode: String) -> Observable<Rate> {
        let request = Rate.filter(Rate.Columns.coinCode == coinCode && Rate.Columns.currencyCode == currencyCode)
        return request.rx.fetchOne(in: dbPool)
                .flatMap { $0.map(Observable.just) ?? Observable.empty() }
    }

    func save(rate: Rate) {
        _ = try? dbPool.write { db in
            try rate.insert(db)
        }
    }

    func clear() {
        _ = try? dbPool.write { db in
            try Rate.deleteAll(db)
        }
    }

}

extension GrdbStorage: ICoinStorage {

    func enabledCoinsObservable() -> Observable<[Coin]> {
        let request = StorableCoin.filter(StorableCoin.Columns.enabled == true).order(StorableCoin.Columns.coinOrder)
        return request.rx.fetchAll(in: dbPool)
                .map { $0.map { $0.coin } }
    }

    func allCoinsObservable() -> Observable<[Coin]> {
        let request = StorableCoin.all().order(StorableCoin.Columns.title)
        return request.rx.fetchAll(in: dbPool)
                .map { $0.map { $0.coin } }
    }

    func save(enabledCoins: [Coin]) {
        _ = try? dbPool.write { db in
            let sql = "UPDATE \(StorableCoin.databaseTableName) SET \(StorableCoin.Columns.enabled.name) = :enabled, \(StorableCoin.Columns.coinOrder.name) = :order"

            try db.execute(sql, arguments: ["enabled": false, "order": nil])

            for (index, coin) in enabledCoins.enumerated() {
                let storableCoin = StorableCoin(coin: coin, enabled: true, order: index)
                try storableCoin.insert(db)
            }
        }
    }

}

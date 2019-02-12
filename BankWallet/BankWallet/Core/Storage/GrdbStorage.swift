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
            try db.create(table: Rate.databaseTableName) { t in
                t.column(Rate.Columns.coinCode.name, .text).notNull()
                t.column(Rate.Columns.currencyCode.name, .text).notNull()
                t.column(Rate.Columns.value.name, .double).notNull()
                t.column(Rate.Columns.timestamp.name, .double).notNull()
                t.column(Rate.Columns.isLatest.name, .boolean).notNull()

                t.primaryKey([
                    Rate.Columns.coinCode.name,
                    Rate.Columns.currencyCode.name,
                    Rate.Columns.timestamp.name,
                    Rate.Columns.isLatest.name
                ], onConflict: .replace)
            }
        }
        migrator.registerMigration("createCoinsTable") { db in
            try db.create(table: StorableCoin.databaseTableName) { t in
                t.column(StorableCoin.Columns.title.name, .text).notNull()
                t.column(StorableCoin.Columns.code.name, .text).notNull()
                t.column(StorableCoin.Columns.type.name, .text).notNull()
                t.column(StorableCoin.Columns.enabled.name, .boolean).notNull()
                t.column(StorableCoin.Columns.coinOrder.name, .integer)

                t.primaryKey([StorableCoin.Columns.code.name], onConflict: .replace)
            }

            let defaultCoins = [
                Coin(title: "Bitcoin", code: "BTC", type: .bitcoin),
                Coin(title: "Bitcoin Cash", code: "BCH", type: .bitcoinCash),
                Coin(title: "Ethereum", code: "ETH", type: .ethereum)
            ]
            for (index, coin) in defaultCoins.enumerated() {
                let storableCoin = StorableCoin(coin: coin, enabled: true, order: index)
                try storableCoin.insert(db)
            }
        }
        migrator.registerMigration("changeRateValueType") { db in
            try db.drop(table: Rate.databaseTableName)

            try db.create(table: Rate.databaseTableName) { t in
                t.column(Rate.Columns.coinCode.name, .text).notNull()
                t.column(Rate.Columns.currencyCode.name, .text).notNull()
                t.column(Rate.Columns.value.name, .text).notNull()
                t.column(Rate.Columns.timestamp.name, .double).notNull()
                t.column(Rate.Columns.isLatest.name, .boolean).notNull()

                t.primaryKey([
                    Rate.Columns.coinCode.name,
                    Rate.Columns.currencyCode.name,
                    Rate.Columns.timestamp.name,
                    Rate.Columns.isLatest.name
                ], onConflict: .replace)
            }
        }

        return migrator
    }

}

extension GrdbStorage: IRateStorage {

    func nonExpiredLatestRateValueObservable(forCoinCode coinCode: CoinCode, currencyCode: String) -> Observable<Decimal> {
        return latestRateObservable(forCoinCode: coinCode, currencyCode: currencyCode)
                .flatMap { rate -> Observable<Decimal> in
                    guard !rate.expired else {
                        return Observable.empty()
                    }
                    return Observable.just(rate.value)
                }
    }

    func latestRateObservable(forCoinCode coinCode: CoinCode, currencyCode: String) -> Observable<Rate> {
        let request = Rate.filter(Rate.Columns.coinCode == coinCode && Rate.Columns.currencyCode == currencyCode && Rate.Columns.isLatest == true)
        return request.rx.fetchOne(in: dbPool)
                .flatMap { $0.map(Observable.just) ?? Observable.empty() }
    }

    func timestampRateObservable(coinCode: CoinCode, currencyCode: String, timestamp: Double) -> Observable<Rate?> {
        let request = Rate.filter(Rate.Columns.coinCode == coinCode && Rate.Columns.currencyCode == currencyCode && Rate.Columns.timestamp == timestamp && Rate.Columns.isLatest == false)
        return request.rx.fetchOne(in: dbPool)
    }

    func zeroValueTimestampRatesObservable(currencyCode: String) -> Observable<[Rate]> {
        let request = Rate.filter(Rate.Columns.currencyCode == currencyCode && Rate.Columns.value == 0 && Rate.Columns.isLatest == false)
        return request.rx.fetchAll(in: dbPool)
    }

    func save(latestRate: Rate) {
        _ = try? dbPool.write { db in
            try Rate.filter(Rate.Columns.coinCode == latestRate.coinCode && Rate.Columns.currencyCode == latestRate.currencyCode && Rate.Columns.isLatest == true).deleteAll(db)
            try latestRate.insert(db)
        }
    }

    func save(rate: Rate) {
        _ = try? dbPool.write { db in
            try rate.insert(db)
        }
    }

    func clearRates() {
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

    func update(inserted: [Coin], deleted: [Coin]) {
        _ = try? dbPool.write { db in
            for coin in inserted {
                let storableCoin = StorableCoin(coin: coin, enabled: false, order: nil)
                try storableCoin.insert(db)
            }
            let deletedCoinCodes = deleted.map { $0.code }
            try StorableCoin.filter(deletedCoinCodes.contains(StorableCoin.Columns.code)).deleteAll(db)
        }
    }

    func clearCoins() {
        _ = try? dbPool.write { db in
            try StorableCoin.deleteAll(db)
        }
    }

}

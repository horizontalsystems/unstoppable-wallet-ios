import RxSwift

class PriceAlertStorage {
    private let coinManager: ICoinManager
    private let storage: IPriceAlertRecordStorage

    init(coinManager: ICoinManager, storage: IPriceAlertRecordStorage) {
        self.coinManager = coinManager
        self.storage = storage
    }

}

extension PriceAlertStorage: IPriceAlertStorage {

    var priceAlerts: [PriceAlert] {
        let coins = coinManager.coins

        return storage.priceAlertRecords.compactMap { record in
            guard let coin = coins.first(where: { $0.code == record.coinCode }) else {
                return nil
            }

            return PriceAlert(coin: coin, changeState: record.changeState, trendState: record.trendState)
        }
    }

    func priceAlert(coin: Coin) -> PriceAlert? {
        storage.priceAlertRecord(forCoinCode: coin.code).flatMap { record in
            PriceAlert(coin: coin, changeState: record.changeState, trendState: record.trendState)
        }
    }

    var activePriceAlerts: [PriceAlert] {
        priceAlerts.filter { $0.changeState != .off || $0.trendState != .off }
    }

    func save(priceAlerts: [PriceAlert]) {
        let records = priceAlerts.map {
            PriceAlertRecord(coinCode: $0.coin.code, changeState: $0.changeState, trendState: $0.trendState)
        }
        storage.save(priceAlertRecords: records)
    }

    func deleteAll() {
        storage.deleteAllPriceAlertRecords()
    }

}

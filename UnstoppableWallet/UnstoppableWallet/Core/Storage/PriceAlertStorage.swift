import RxSwift
import MarketKit

class PriceAlertStorage {
    private let storage: IPriceAlertRecordStorage

    init(storage: IPriceAlertRecordStorage) {
        self.storage = storage
    }

}

extension PriceAlertStorage: IPriceAlertStorage {

    var priceAlerts: [PriceAlert] {
        storage.priceAlertRecords.map { record in
            PriceAlert(coinType: CoinType(id: record.coinId), coinTitle: record.coinTitle, changeState: record.changeState, trendState: record.trendState)
        }
    }

    func priceAlert(coinType: CoinType) -> PriceAlert? {
        storage.priceAlertRecord(forCoinId: coinType.id).flatMap { record in
            PriceAlert(coinType: coinType, coinTitle: record.coinTitle, changeState: record.changeState, trendState: record.trendState)
        }
    }

    var activePriceAlerts: [PriceAlert] {
        priceAlerts.filter { $0.changeState != .off || $0.trendState != .off }
    }

    func save(priceAlerts: [PriceAlert]) {
        let records = priceAlerts.map {
            PriceAlertRecord(coinId: $0.coinType.id, coinTitle: $0.coinTitle, changeState: $0.changeState, trendState: $0.trendState)
        }

        storage.save(priceAlertRecords: records)
    }

    func deleteAll() {
        storage.deleteAllPriceAlertRecords()
    }

}

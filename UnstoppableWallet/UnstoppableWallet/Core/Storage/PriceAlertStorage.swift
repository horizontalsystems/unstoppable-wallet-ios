import RxSwift
import CoinKit

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
            guard let coin = coins.first(where: { $0.id == record.coinId }) else {
                return nil
            }

            return PriceAlert(coinType: coin.type, changeState: record.changeState, trendState: record.trendState)
        }
    }

    func priceAlert(coinType: CoinType) -> PriceAlert? {
        storage.priceAlertRecord(forCoinId: coinType.id).flatMap { record in
            PriceAlert(coinType: coinType, changeState: record.changeState, trendState: record.trendState)
        }
    }

    var activePriceAlerts: [PriceAlert] {
        return priceAlerts.filter { $0.changeState != .off || $0.trendState != .off }
    }

    func save(priceAlerts: [PriceAlert]) {
        let records = priceAlerts.map {
            PriceAlertRecord(coinId: $0.coinType.id, changeState: $0.changeState, trendState: $0.trendState)
        }

        storage.save(priceAlertRecords: records)
    }

    func deleteAll() {
        storage.deleteAllPriceAlertRecords()
    }

}

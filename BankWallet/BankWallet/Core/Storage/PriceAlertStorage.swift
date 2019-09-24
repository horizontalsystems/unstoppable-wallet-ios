import RxSwift

class PriceAlertStorage {
    private let appConfigProvider: IAppConfigProvider
    private let storage: IPriceAlertRecordStorage

    init(appConfigProvider: IAppConfigProvider, storage: IPriceAlertRecordStorage) {
        self.appConfigProvider = appConfigProvider
        self.storage = storage
    }

}

extension PriceAlertStorage: IPriceAlertStorage {

    var priceAlerts: [PriceAlert] {
        let coins = appConfigProvider.coins

        return storage.priceAlertRecords.compactMap { record in
            guard let coin = coins.first(where: { $0.code == record.coinCode }) else {
                return nil
            }

            return PriceAlert(coin: coin, state: record.state, lastRate: record.lastRate)
        }
    }

    var activePriceAlerts: [PriceAlert] {
        priceAlerts.filter { $0.state != .off }
    }

    func save(priceAlerts: [PriceAlert]) {
        let records = priceAlerts.map {
            PriceAlertRecord(coinCode: $0.coin.code, state: $0.state, lastRate: $0.lastRate)
        }
        storage.save(priceAlertRecords: records)
    }

    func delete(priceAlerts: [PriceAlert]) {
        let coinCodes = priceAlerts.map { $0.coin.code }
        storage.deletePriceAlertRecords(coinCodes: coinCodes)
    }

    func deleteExcluding(coinCodes: [CoinCode]) {
        storage.deletePriceAlertsExcluding(coinCodes: coinCodes)
    }

}

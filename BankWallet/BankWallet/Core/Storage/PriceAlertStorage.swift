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

            return PriceAlert(coin: coin, state: record.state)
        }
    }

    var priceAlertCount: Int {
        return storage.priceAlertRecordCount
    }

    func save(priceAlert: PriceAlert) {
        let record = PriceAlertRecord(coinCode: priceAlert.coin.code, state: priceAlert.state)
        storage.save(priceAlertRecord: record)
    }

    func delete(priceAlert: PriceAlert) {
        storage.deletePriceAlertRecord(coinCode: priceAlert.coin.code)
    }

}

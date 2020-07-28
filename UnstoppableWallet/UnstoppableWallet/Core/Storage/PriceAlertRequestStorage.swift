import RxSwift

class PriceAlertRequestStorage {
    private let storage: IPriceAlertRequestRecordStorage

    init(storage: IPriceAlertRequestRecordStorage) {
        self.storage = storage
    }

}

extension PriceAlertRequestStorage: IPriceAlertRequestStorage {

    var requests: [PriceAlertRequest] {
        storage.priceAlertRequestRecords.compactMap {
            PriceAlertRequest(topic: $0.topic, method: $0.method)
        }
    }

    func save(requests: [PriceAlertRequest]) {
        let records = requests.map {
            PriceAlertRequestRecord(topic: $0.topic, method: $0.method)
        }
        storage.save(priceAlertRequestRecords: records)
    }

    func delete(requests: [PriceAlertRequest]) {
        let records = requests.map {
            PriceAlertRequestRecord(topic: $0.topic, method: $0.method)
        }
        storage.delete(priceAlertRequestRecords: records)
    }

}

import Foundation

struct NftPriceRecord {
    let coinTypeId: String
    let value: Decimal

    init(price: NftPrice) {
        coinTypeId = price.platformCoin.coinType.id
        value = price.value
    }

    init?(coinTypeId: String?, value: Decimal?) {
        if let coinTypeId = coinTypeId, let value = value {
            self.coinTypeId = coinTypeId
            self.value = value
        } else {
            return nil
        }
    }
}

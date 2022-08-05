import Foundation
import MarketKit

struct NftPriceRecord {
    let tokenQuery: TokenQuery
    let value: Decimal

    init(price: NftPrice) {
        tokenQuery = price.token.tokenQuery
        value = price.value
    }

    init?(tokenQueryId: String?, value: Decimal?) {
        if let tokenQueryId = tokenQueryId, let tokenQuery = TokenQuery(id: tokenQueryId), let value = value {
            self.tokenQuery = tokenQuery
            self.value = value
        } else {
            return nil
        }
    }
}

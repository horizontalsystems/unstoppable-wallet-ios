import Foundation
import RxSwift
import RxRelay
import MarketKit

class TokenTransactionsService: BaseTransactionsService {
    private let token: Token

    init(token: Token, rateService: HistoricalRateService, nftMetadataService: NftMetadataService) {
        self.token = token

        super.init(rateService: rateService, nftMetadataService: nftMetadataService)

        _syncCanReset()
        _syncPoolGroup()
    }

    override var _poolGroupType: PoolGroupFactory.PoolGroupType {
        .token(token: token)
    }

}

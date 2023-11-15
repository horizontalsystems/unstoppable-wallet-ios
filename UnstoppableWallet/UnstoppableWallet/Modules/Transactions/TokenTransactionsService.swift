import Foundation
import MarketKit
import RxRelay
import RxSwift

class TokenTransactionsService: BaseTransactionsService {
    private let token: Token
    private let disposeBag = DisposeBag()

    init(token: Token, adapterManager: TransactionAdapterManager, rateService: HistoricalRateService, nftMetadataService: NftMetadataService) {
        self.token = token

        super.init(
            rateService: rateService,
            nftMetadataService: nftMetadataService,
            balanceHiddenManager: App.shared.balanceHiddenManager
        )

        subscribe(disposeBag, adapterManager.adaptersReadyObservable) { [weak self] _ in self?.sync() }

        _sync()
    }

    private func sync() {
        queue.async {
            self._sync()
        }
    }

    private func _sync() {
        _syncPoolGroup()
    }

    override var _poolGroupType: PoolGroupFactory.PoolGroupType {
        .token(token: token)
    }
}

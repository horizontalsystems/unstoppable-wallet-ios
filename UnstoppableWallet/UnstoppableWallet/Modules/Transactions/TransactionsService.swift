import Combine
import Foundation
import HsExtensions
import MarketKit
import RxSwift

class TransactionsService: BaseTransactionsService {
    private let walletManager: WalletManager
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    @DistinctPublished var transactionFilter = TransactionFilter() {
        didSet {
            syncPoolGroup()
        }
    }

    init(walletManager: WalletManager, adapterManager: TransactionAdapterManager, rateService: HistoricalRateService, nftMetadataService: NftMetadataService, balanceHiddenManager: BalanceHiddenManager) {
        self.walletManager = walletManager

        super.init(rateService: rateService, nftMetadataService: nftMetadataService, balanceHiddenManager: balanceHiddenManager)

        subscribe(disposeBag, adapterManager.adaptersReadyObservable) { [weak self] _ in
            self?.syncPoolGroup()
        }

        _syncPoolGroup()
    }

    private func syncPoolGroup() {
        queue.async {
            self._syncPoolGroup()
        }
    }

    override var _poolGroupType: PoolGroupFactory.PoolGroupType {
        if let token = transactionFilter.token {
            return .token(token: token)
        } else if let blockchain = transactionFilter.blockchain {
            return .blockchain(blockchainType: blockchain.type, wallets: walletManager.activeWallets)
        } else {
            return .all(wallets: walletManager.activeWallets)
        }
    }

    override var contact: Contact? {
        transactionFilter.contact
    }

    override var scamFilterEnabled: Bool {
        transactionFilter.scamFilterEnabled
    }
}

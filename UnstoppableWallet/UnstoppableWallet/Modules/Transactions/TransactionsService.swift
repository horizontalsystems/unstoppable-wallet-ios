import Combine
import Foundation
import MarketKit
import RxSwift

class TransactionsService: BaseTransactionsService {
    let filterService: TransactionFilterService
    private let walletManager: WalletManager
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    init(filterService: TransactionFilterService, walletManager: WalletManager, adapterManager: TransactionAdapterManager, rateService: HistoricalRateService, nftMetadataService: NftMetadataService, balanceHiddenManager: BalanceHiddenManager) {
        self.filterService = filterService
        self.walletManager = walletManager

        super.init(rateService: rateService, nftMetadataService: nftMetadataService, balanceHiddenManager: balanceHiddenManager)

        filterService.$transactionFilter
            .sink { [weak self] _ in
                self?.syncPoolGroup()
            }
            .store(in: &cancellables)

        subscribe(disposeBag, walletManager.activeWalletDataUpdatedObservable) { [weak self] activeWalletData in
            self?.filterService.handle(wallets: activeWalletData.wallets)
        }

        subscribe(disposeBag, App.shared.contactManager.stateObservable) { [weak self] _ in
            self?.filterService.handleContacts(filter: nil)
        }

        subscribe(disposeBag, adapterManager.adaptersReadyObservable) { [weak self] _ in
            self?.syncPoolGroup()
        }

        _syncPoolGroup()
        filterService.handle(wallets: walletManager.activeWallets)
    }

    private func syncPoolGroup() {
        queue.async {
            self._syncPoolGroup()
        }
    }

    override var _poolGroupType: PoolGroupFactory.PoolGroupType {
        if let token = filterService.transactionFilter.token {
            return .token(token: token)
        } else if let blockchain = filterService.transactionFilter.blockchain {
            return .blockchain(blockchainType: blockchain.type, wallets: walletManager.activeWallets)
        } else {
            return .all(wallets: walletManager.activeWallets)
        }
    }

    override var contact: Contact? {
        filterService.transactionFilter.contact
    }

    override var scamFilterEnabled: Bool {
        filterService.transactionFilter.scamFilterEnabled
    }
}

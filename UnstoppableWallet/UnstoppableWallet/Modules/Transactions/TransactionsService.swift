import Foundation
import RxSwift
import RxRelay
import MarketKit

class TransactionsService: BaseTransactionsService {
    private let walletManager: WalletManager

    private let blockchainRelay = PublishRelay<Blockchain?>()
    private(set) var blockchain: Blockchain? {
        didSet {
            blockchainRelay.accept(blockchain)
        }
    }

    private let tokenRelay = PublishRelay<Token?>()
    private(set) var token: Token? {
        didSet {
            tokenRelay.accept(token)
        }
    }

    private(set) var allBlockchains = [Blockchain]()

    init(walletManager: WalletManager, adapterManager: TransactionAdapterManager, rateService: HistoricalRateService, nftMetadataService: NftMetadataService) {
        self.walletManager = walletManager

        super.init(rateService: rateService, nftMetadataService: nftMetadataService)

        subscribe(disposeBag, adapterManager.adaptersReadyObservable) { [weak self] _ in self?.syncWallets() }

        _syncWallets()
    }

    override var _canReset: Bool {
        super._canReset || blockchain != nil || token != nil
    }

    private func syncWallets() {
        queue.async {
            self._syncWallets()
        }
    }

    private func _syncWallets() {
        allBlockchains = Array(Set(walletManager.activeWallets.map { $0.token.blockchain }))

        if let blockchain = blockchain, !allBlockchains.contains(blockchain) {
            self.blockchain = nil
        }

        if let token, !walletManager.activeWallets.contains(where: { $0.token == token }) {
            self.token = nil
            blockchain = nil
        }

        _syncCanReset()

//        print("SYNC POOL GROUP: sync wallets: \(walletManager.activeWallets.count)")
        _syncPoolGroup()
    }

    override var _poolGroupType: PoolGroupFactory.PoolGroupType {
        if let token {
            return .token(token: token)
        } else if let blockchain {
            return .blockchain(blockchainType: blockchain.type, wallets: walletManager.activeWallets)
        } else {
            return .all(wallets: walletManager.activeWallets)
        }
    }

    override func _resetFilters() {
        super._resetFilters()

        blockchain = nil
        token = nil
    }

}

extension TransactionsService {

    var blockchainObservable: Observable<Blockchain?> {
        blockchainRelay.asObservable()
    }

    var tokenObservable: Observable<Token?> {
        tokenRelay.asObservable()
    }

    func set(blockchain: Blockchain?) {
        queue.async {
            guard self.blockchain != blockchain else {
                return
            }

            self.blockchain = blockchain
            self.token = nil

            self._syncCanReset()

//            print("SYNC POOL GROUP: set blockchain")
            self._syncPoolGroup()
        }
    }

    func set(token: Token?) {
        queue.async {
            guard self.token != token else {
                return
            }

            self.token = token
            self.blockchain = token?.blockchain

            self._syncCanReset()

//            print("SYNC POOL GROUP: set token")
            self._syncPoolGroup()
        }
    }

}

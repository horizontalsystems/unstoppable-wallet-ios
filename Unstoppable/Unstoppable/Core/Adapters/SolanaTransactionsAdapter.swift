import Combine
import Foundation
import MarketKit
import RxSwift
import SolanaKit

class SolanaTransactionsAdapter {
    private let solanaKit: SolanaKit.Kit
    private let converter: SolanaTransactionConverter
    private var cancellables = Set<AnyCancellable>()

    private let adapterStateSubject = PublishSubject<AdapterState>()
    private(set) var adapterState: AdapterState {
        didSet {
            adapterStateSubject.onNext(adapterState)
        }
    }

    init(solanaKit: SolanaKit.Kit, source: TransactionSource, baseToken: Token, coinManager: CoinManager) {
        self.solanaKit = solanaKit
        converter = SolanaTransactionConverter(
            userAddress: solanaKit.address,
            source: source,
            baseToken: baseToken,
            coinManager: coinManager
        )

        adapterState = Self.adapterState(kitSyncState: solanaKit.transactionsSyncState)

        solanaKit.transactionsSyncStatePublisher
            .sink { [weak self] in self?.adapterState = Self.adapterState(kitSyncState: $0) }
            .store(in: &cancellables)
    }

    private func incomingFilter(filter: TransactionTypeFilter) -> Bool? {
        switch filter {
        case .all: return nil
        case .incoming: return true
        case .outgoing: return false
        default: return nil
        }
    }

    private static func adapterState(kitSyncState: SolanaKit.SyncState) -> AdapterState {
        switch kitSyncState {
        case .syncing: return .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
        case .synced: return .synced
        case let .notSynced(error): return .notSynced(error: error.localizedDescription)
        }
    }
}

extension SolanaTransactionsAdapter: ITransactionsAdapter {
    var syncing: Bool {
        adapterState.syncing
    }

    var syncingObservable: Observable<Void> {
        adapterStateSubject.map { _ in () }
    }

    var lastBlockInfo: LastBlockInfo? {
        LastBlockInfo(height: Int(solanaKit.lastBlockHeight), timestamp: nil)
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        solanaKit.lastBlockHeightPublisher.map { _ in () }.asObservable()
    }

    var explorerTitle: String {
        "Solscan.io"
    }

    var additionalTokenQueries: [TokenQuery] {
        solanaKit.fungibleTokenAccounts().map { fullAccount in
            TokenQuery(blockchainType: .solana, tokenType: .spl(address: fullAccount.tokenAccount.mintAddress))
        }
    }

    func explorerUrl(transactionHash: String) -> String? {
        "https://solscan.io/tx/\(transactionHash)"
    }

    func transactionsObservable(token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> Observable<[TransactionRecord]> {
        // Address filtering not supported
        if address != nil {
            return Observable.just([])
        }

        let incoming = incomingFilter(filter: filter)

        // For unsupported filter types (.swap, .approve), return empty
        if case .swap = filter {
            return Observable.just([])
        }
        if case .approve = filter {
            return Observable.just([])
        }

        let publisher: AnyPublisher<[FullTransaction], Never>

        if let token {
            switch token.type {
            case .native:
                publisher = solanaKit.solTransactionsPublisher(incoming: incoming)
            case let .spl(address):
                publisher = solanaKit.splTransactionsPublisher(mintAddress: address, incoming: incoming)
            default:
                return Observable.just([])
            }
        } else {
            publisher = solanaKit.allTransactionsPublisher(incoming: incoming)
        }

        return publisher
            .map { [converter] transactions in
                transactions.map { converter.transactionRecord(fullTransaction: $0) }
            }
            .asObservable()
    }

    func transactionsSingle(paginationData: String?, token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?, limit: Int) -> Single<[TransactionRecord]> {
        // Address filtering not supported
        if address != nil {
            return Single.just([])
        }

        switch filter {
        case .all, .incoming, .outgoing: break
        default: return Single.just([])
        }

        let fromHash = paginationData
        let incoming = incomingFilter(filter: filter)

        return Single.create { [solanaKit, converter] observer in
            Task {
                let transactions: [FullTransaction]

                if let token {
                    switch token.type {
                    case .native:
                        transactions = solanaKit.solTransactions(incoming: incoming, fromHash: fromHash, limit: limit)
                    case let .spl(address):
                        transactions = solanaKit.splTransactions(mintAddress: address, incoming: incoming, fromHash: fromHash, limit: limit)
                    default:
                        transactions = []
                    }
                } else {
                    transactions = solanaKit.transactions(incoming: incoming, fromHash: fromHash, limit: limit)
                }

                let records = transactions.map { converter.transactionRecord(fullTransaction: $0) }
                observer(.success(records))
            }

            return Disposables.create()
        }
    }

    func allTransactionsAfter(paginationData: String?) -> Single<[TransactionRecord]> {
        let fromHash = paginationData

        return Single.create { [solanaKit, converter] observer in
            Task {
                let transactions = solanaKit.transactions(incoming: nil, fromHash: fromHash, limit: nil)
                let records = transactions.map { converter.transactionRecord(fullTransaction: $0) }
                observer(.success(records))
            }

            return Disposables.create()
        }
    }

    func rawTransaction(hash _: String) -> String? {
        nil
    }
}

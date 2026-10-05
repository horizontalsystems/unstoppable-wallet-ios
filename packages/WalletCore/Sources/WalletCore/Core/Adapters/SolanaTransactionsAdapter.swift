import Combine
import Foundation
import MarketKit
import RxSwift
import SolanaKit

class SolanaTransactionsAdapter {
    private let solanaKit: SolanaKit.Kit
    private let converter: SolanaTransactionConverter
    private let spamManager: SpamManager?
    private var cancellables = Set<AnyCancellable>()

    private let adapterStateSubject = PublishSubject<AdapterState>()
    private(set) var adapterState: AdapterState {
        didSet {
            adapterStateSubject.onNext(adapterState)
        }
    }

    init(solanaKit: SolanaKit.Kit, source: TransactionSource, baseToken: Token, coinManager: CoinManager, spamWrapper: SpamWrapper) {
        self.solanaKit = solanaKit
        spamManager = spamWrapper.spamManager(source: source)
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

        spamManager?.initialize(adapter: self)
    }

    private func handleTransactions(_ transactions: [FullTransaction]) -> [TransactionRecord] {
        // Preserve solanaKit order
        let records = transactions.map { converter.transactionRecord(fullTransaction: $0) }

        // Mutates .spam in-place via reference type.
        // Internally sorts ascending for correct detection,
        // but records array keeps its original order.
        spamManager?.update(records: records)

        return records
    }

    // The kit picks a coin's rows by a raw SOL or SPL movement, so a token send that paid the recipient's
    // account rent lands in SOL. Keep a recognized transfer or swap only when its resolved operation moves
    // the coin; anything else (unknown, a swap without sides yet) keeps today's behavior.
    private static func movesToken(_ record: TransactionRecord, token: Token) -> Bool {
        switch record {
        case let record as SolanaIncomingTransactionRecord:
            return record.value.token == token
        case let record as SolanaOutgoingTransactionRecord:
            return record.value.token == token
        case let record as SolanaSwapTransactionRecord:
            let values = [record.valueIn, record.valueOut].compactMap { $0 }
            return values.isEmpty || values.contains { $0.token == token }
        default:
            return true
        }
    }

    private func records(_ transactions: [FullTransaction], token: Token?) -> [TransactionRecord] {
        let records = handleTransactions(transactions)

        guard let token else {
            return records
        }

        return records.filter { Self.movesToken($0, token: token) }
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
        case let .notSynced(error):
            if let syncError = error as? SolanaKit.SyncError, case .notStarted = syncError {
                return .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
            }
            return .notSynced(error: error.localizedDescription)
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
            .map { [weak self] in self?.records($0, token: token) ?? [] }
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

        let incoming = incomingFilter(filter: filter)

        return Single.create { [weak self, solanaKit] observer in
            Task {
                var records = [TransactionRecord]()
                var fromHash = paginationData

                // A filtered page comes back short, and a short page ends the history for the pool:
                // keep reading until the page is full or the kit has nothing more
                while true {
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

                    records += self?.records(transactions, token: token) ?? []

                    guard records.count < limit, transactions.count == limit, let lastHash = transactions.last?.transaction.hash else {
                        break
                    }

                    fromHash = lastHash
                }

                observer(.success(Array(records.prefix(limit))))
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

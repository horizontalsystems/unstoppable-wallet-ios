import BigInt
import Combine
import Foundation
import MarketKit
import RxSwift
import StellarKit

class StellarTransactionAdapter {
    private let stellarKit: StellarKit.Kit
    private let converter: StellarOperationConverter
    private let spamWrapper: SpamWrapper
    private let spamManager: SpamManager?

    private var cancellables = Set<AnyCancellable>()

    private let adapterStateSubject = PublishSubject<AdapterState>()
    private(set) var adapterState: AdapterState {
        didSet {
            adapterStateSubject.onNext(adapterState)
        }
    }

    init(stellarKit: StellarKit.Kit, source: TransactionSource, baseToken: Token, coinManager: CoinManager, spamWrapper: SpamWrapper) {
        self.stellarKit = stellarKit
        self.spamWrapper = spamWrapper
        spamManager = spamWrapper.spamManager(source: source)

        converter = StellarOperationConverter(
            accountId: stellarKit.receiveAddress,
            source: source,
            baseToken: baseToken,
            coinManager: coinManager
        )

        adapterState = Self.adapterState(kitSyncState: stellarKit.operationSyncState)
        initializeSpamManager()

        stellarKit.operationSyncStatePublisher
            .sink { [weak self] in self?.adapterState = Self.adapterState(kitSyncState: $0) }
            .store(in: &cancellables)
    }

    private func initializeSpamManager() {
        spamManager?.initialize(adapter: self)
    }

    private func tagQuery(token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> TagQuery {
        var type: Tag.`Type`?
        var asset: Asset?
        var accountId: String?

        if let token {
            switch token.type {
            case .native:
                asset = .native
            case let .stellar(code, issuer):
                asset = .asset(code: code, issuer: issuer)
            default: ()
            }
        }

        switch filter {
        case .all: ()
        case .incoming: type = .incoming
        case .outgoing: type = .outgoing
        }

        if let address {
            do {
                try StellarKit.Kit.validate(accountId: address)
                accountId = address
            } catch {}
        }

        return TagQuery(type: type, assetId: asset?.id, accountId: accountId)
    }

    private static func adapterState(kitSyncState: StellarKit.SyncState) -> AdapterState {
        switch kitSyncState {
        case .syncing: return .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
        case .synced: return .synced
        case let .notSynced(error): return .notSynced(error: error.localizedDescription)
        }
    }
}

extension StellarTransactionAdapter: ITransactionsAdapter {
    var syncing: Bool {
        adapterState.syncing
    }

    var syncingObservable: Observable<Void> {
        adapterStateSubject.map { _ in () }
    }

    var lastBlockInfo: LastBlockInfo? {
        nil
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        Observable.empty()
    }

    var explorerTitle: String {
        "stellar.expert"
    }

    var additionalTokenQueries: [TokenQuery] {
        stellarKit.operationAssets().compactMap { asset in
            let tokenType: TokenType

            switch asset {
            case .native:
                tokenType = .native
            case let .asset(code, issuer):
                tokenType = .stellar(code: code, issuer: issuer)
            }

            return TokenQuery(blockchainType: .stellar, tokenType: tokenType)
        }
    }

    func explorerUrl(transactionHash: String) -> String? {
        "https://stellar.expert/explorer/public/tx/\(transactionHash)"
    }

    /// A transaction's operations can straddle the page boundary of a limited fetch (a
    /// fee-bearing STELLAR_DEX swap is exactly 2 ops) — grouping only within the page would
    /// then emit two records with the same hash: a duplicate list row, one mis-typed. When a
    /// page came back full, pull the ops that complete its last transaction (local-storage
    /// reads, one op per peek).
    private func completingLastTransaction(_ operations: [TxOperation], tagQuery: TagQuery, limit: Int) -> [TxOperation] {
        guard operations.count == limit, var last = operations.last else { return operations }
        var result = operations
        while true {
            guard let next = stellarKit.operations(tagQuery: tagQuery, pagingToken: last.pagingToken, descending: true, limit: 1).first,
                  next.transactionHash == last.transactionHash
            else { return result }
            result.append(next)
            last = next
        }
    }

    /// Operations of the same transaction are adjacent in ledger order (either sort
    /// direction), so consecutive grouping by hash is enough to yield one record per tx.
    private static func groupedByTransaction(_ operations: [TxOperation]) -> [[TxOperation]] {
        operations.reduce(into: [[TxOperation]]()) { groups, operation in
            if let last = groups.last, last[0].transactionHash == operation.transactionHash {
                groups[groups.count - 1].append(operation)
            } else {
                groups.append([operation])
            }
        }
    }

    private func handleTransactions(_ operations: [TxOperation]) -> [TransactionRecord] {
        // Preserve stellarKit order
        let records = Self.groupedByTransaction(operations).map { converter.transactionRecord(operations: $0) }

        // Mutates .spam in-place via reference type.
        // Internally sorts ascending for correct detection,
        // but records array keeps its original order.
        spamManager?.update(records: records)

        return records
    }

    func transactionsObservable(token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> Observable<[TransactionRecord]> {
        stellarKit.operationPublisher(tagQuery: tagQuery(token: token, filter: filter, address: address))
            .asObservable()
            .map { [weak self] in
                self?.handleTransactions($0.operations) ?? []
            }
    }

    func transactionsSingle(paginationData: String?, token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?, limit: Int) -> Single<[TransactionRecord]> {
        let tagQuery = tagQuery(token: token, filter: filter, address: address)
        let pagingToken = paginationData

        return Single.create { [weak self, stellarKit] observer in
            Task { [weak self, stellarKit] in

                let operations = stellarKit.operations(tagQuery: tagQuery, pagingToken: pagingToken, descending: true, limit: limit)
                let completed = self?.completingLastTransaction(operations, tagQuery: tagQuery, limit: limit) ?? operations
                let records = self?.handleTransactions(completed) ?? []

                observer(.success(records))
            }

            return Disposables.create()
        }
    }

    func allTransactionsAfter(paginationData: String?) -> Single<[TransactionRecord]> {
        let pagingToken = paginationData

        return Single.create { [weak self, stellarKit] observer in
            Task { [weak self, stellarKit] in

                let operations = stellarKit.operations(tagQuery: .init(), pagingToken: pagingToken, descending: false, limit: nil)
                let records = Self.groupedByTransaction(operations).compactMap { self?.converter.transactionRecord(operations: $0) }

                observer(.success(records))
            }

            return Disposables.create()
        }
    }

    func rawTransaction(hash _: String) -> String? {
        nil
    }
}

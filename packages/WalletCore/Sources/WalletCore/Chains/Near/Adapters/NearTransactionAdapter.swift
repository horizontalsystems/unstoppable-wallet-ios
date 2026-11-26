import Combine
import Foundation
import MarketKit
import NearKit
import RxSwift

class NearTransactionAdapter {
    /// the kit pages its local table by (timestamp, hash); filters apply here, so pages are read until enough match
    private static let pageSize = 100

    private let nearKit: NearKit.Kit
    private let converter: NearTransactionConverter
    private let spamManager: SpamManager?
    private var cancellables = Set<AnyCancellable>()

    private let adapterStateSubject = PublishSubject<AdapterState>()
    private(set) var adapterState: AdapterState {
        didSet {
            adapterStateSubject.onNext(adapterState)
        }
    }

    init(nearKit: NearKit.Kit, source: TransactionSource, baseToken: Token, coinManager: CoinManager, spamWrapper: SpamWrapper) {
        self.nearKit = nearKit
        spamManager = spamWrapper.spamManager(source: source)
        converter = NearTransactionConverter(
            accountId: nearKit.accountId,
            source: source,
            baseToken: baseToken,
            coinManager: coinManager,
            ftMetadata: { [weak nearKit] contractId in
                guard let nearKit else { throw CancellationError() }
                return try await nearKit.ftMetadata(contractId: contractId)
            }
        )

        adapterState = NearAdapter.adapterState(kitSyncState: nearKit.transactionsSyncState)

        nearKit.transactionsSyncStatePublisher
            .sink { [weak self] in self?.adapterState = NearAdapter.adapterState(kitSyncState: $0) }
            .store(in: &cancellables)

        spamManager?.initialize(adapter: self)
    }

    private func records(transactions: [NearKit.Transaction]) async -> [TransactionRecord] {
        var records = [TransactionRecord]()
        for transaction in transactions {
            await records.append(converter.transactionRecord(transaction: transaction))
        }

        // Mutates .spam in-place via reference type; keeps the kit's order.
        spamManager?.update(records: records)

        return records
    }

    private func single(_ work: @escaping () async throws -> [TransactionRecord]) -> Single<[TransactionRecord]> {
        Single.create { observer in
            let task = Task {
                do {
                    let records = try await work()
                    observer(.success(records))
                } catch {
                    // the kit's store is unreadable: surface it instead of showing an empty history
                    observer(.error(error))
                }
            }

            return Disposables.create { task.cancel() }
        }
    }

    /// The kit's history tag: nil for every transaction, `tokenNative` or a token contract id. Nil
    /// result when the token is not a NEAR token at all.
    private func tag(token: MarketKit.Token?) -> String?? {
        guard let token else {
            return .some(nil)
        }

        switch token.type {
        case .native: return .some(NearKit.Kit.tokenNative)
        case let .nep141(contractId): return .some(contractId)
        default: return nil
        }
    }

    private func matcher(filter: TransactionTypeFilter, address: String?) -> (NearKit.Transaction) -> Bool {
        let accountId = nearKit.accountId
        let typeMatches: (NearKit.Transaction) -> Bool

        switch filter {
        case .all: typeMatches = { _ in true }
        case .incoming: typeMatches = { !$0.isSigner(accountId: accountId) }
        case .outgoing: typeMatches = { $0.isSigner(accountId: accountId) }
        }

        guard let address else {
            return typeMatches
        }

        return { transaction in
            typeMatches(transaction) && (
                transaction.signerId == address || transaction.receiverId == address ||
                    transaction.ftTransfers.contains { $0.from == address || $0.to == address }
            )
        }
    }
}

extension NearTransactionAdapter: ITransactionsAdapter {
    var syncing: Bool {
        adapterState.syncing
    }

    var syncingObservable: Observable<Void> {
        adapterStateSubject.map { _ in () }
    }

    var lastBlockInfo: LastBlockInfo? {
        LastBlockInfo(height: nearKit.lastBlockHeight, timestamp: nil)
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        nearKit.lastBlockHeightPublisher.map { _ in () }.asObservable()
    }

    var explorerTitle: String {
        "NearBlocks"
    }

    var additionalTokenQueries: [TokenQuery] {
        nearKit.ftBalances.map { TokenQuery(blockchainType: .near, tokenType: .nep141(contractId: $0.contractId)) }
    }

    func explorerUrl(transactionHash: String) -> String? {
        nearKit.network.transactionUrl(hash: transactionHash)
    }

    func transactionsObservable(token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> Observable<[TransactionRecord]> {
        guard let tag = tag(token: token) else {
            return Observable.just([])
        }

        let matches = matcher(filter: filter, address: address)

        return nearKit.transactionsPublisher(token: tag)
            .asObservable()
            .map { $0.filter(matches) }
            .concatMap { [weak self] transactions -> Single<[TransactionRecord]> in
                guard let self, !transactions.isEmpty else {
                    return Single.just([])
                }
                return single { await self.records(transactions: transactions) }
            }
    }

    func transactionsSingle(paginationData: String?, token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?, limit: Int) -> Single<[TransactionRecord]> {
        guard let tag = tag(token: token) else {
            return Single.just([])
        }

        let matches = matcher(filter: filter, address: address)
        let pageSize = Self.pageSize

        return single { [weak self, nearKit] in
            var anchor = try paginationData.flatMap { try nearKit.transaction(hash: $0) }.map { (timestamp: $0.timestamp, hash: $0.hash) }
            var result = [NearKit.Transaction]()

            while result.count < limit {
                let page = try nearKit.transactions(token: tag, beforeTimestamp: anchor?.timestamp, beforeHash: anchor?.hash, limit: pageSize)
                result += page.filter(matches)

                guard page.count == pageSize, let last = page.last else { break }
                anchor = (timestamp: last.timestamp, hash: last.hash)
            }

            return await self?.records(transactions: Array(result.prefix(limit))) ?? []
        }
    }

    func allTransactionsAfter(paginationData: String?) -> Single<[TransactionRecord]> {
        let pageSize = Self.pageSize

        return single { [nearKit, converter] in
            let anchorTimestamp = try paginationData.flatMap { try nearKit.transaction(hash: $0) }?.timestamp
            var result = [NearKit.Transaction]()
            var before: (timestamp: Int, hash: String)?

            while true {
                let page = try nearKit.transactions(token: nil, beforeTimestamp: before?.timestamp, beforeHash: before?.hash, limit: pageSize)
                let newer = anchorTimestamp.map { anchor in Array(page.prefix { $0.timestamp > anchor }) } ?? page
                result += newer

                guard page.count == pageSize, newer.count == page.count, let last = page.last else { break }
                before = (timestamp: last.timestamp, hash: last.hash)
            }

            // records for the spam scan only: unknown token metadata is not read
            var records = [TransactionRecord]()
            for transaction in result {
                await records.append(converter.transactionRecord(transaction: transaction, resolvesUnknownMetadata: false))
            }
            return records
        }
    }

    func rawTransaction(hash _: String) -> String? {
        nil
    }
}

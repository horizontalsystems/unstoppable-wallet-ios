import Combine
import Foundation
import MarketKit
import RxSwift
import ThorChainKit

class ThorChainTransactionsAdapter {
    private let thorChainKitWrapper: ThorChainKitWrapper
    private let converter: ThorChainTransactionConverter

    init(thorChainKitWrapper: ThorChainKitWrapper, source: TransactionSource, baseToken: Token, coinManager: CoinManager) {
        self.thorChainKitWrapper = thorChainKitWrapper
        converter = ThorChainTransactionConverter(
            source: source,
            baseToken: baseToken,
            coinManager: coinManager,
            thorChainKitWrapper: thorChainKitWrapper
        )
    }

    private var thorChainKit: ThorChainKit.Kit {
        thorChainKitWrapper.thorChainKit
    }

    private func records(from transactions: [ThorChainKit.Transaction], token: Token?, filter: TransactionTypeFilter, address: String?) -> [TransactionRecord] {
        transactions
            .flatMap { converter.transactionRecords(from: $0) }
            .filter { matches(record: $0, token: token, filter: filter, address: address) }
    }

    private func matches(record: ThorChainTransactionRecord, token: Token?, filter: TransactionTypeFilter, address: String?) -> Bool {
        switch filter {
        case .all: break
        case .incoming: guard record is ThorChainIncomingTransactionRecord else { return false }
        case .outgoing: guard record is ThorChainOutgoingTransactionRecord else { return false }
        default: return false
        }

        // One action yields a record per user-side asset, so an action can carry both
        // RUNE and a THORChain asset. Without this the RUNE wallet lists them all.
        if let token, record.mainValue?.token?.coin.uid != token.coin.uid {
            return false
        }

        if let address {
            let counterparty: String?

            switch record {
            case let record as ThorChainIncomingTransactionRecord: counterparty = record.from
            case let record as ThorChainOutgoingTransactionRecord: counterparty = record.to
            default: counterparty = nil
            }

            guard let counterparty, counterparty.caseInsensitiveCompare(address) == .orderedSame else {
                return false
            }
        }

        return true
    }
}

extension ThorChainTransactionsAdapter: ITransactionsAdapter {
    var syncing: Bool {
        thorChainKit.transactionsSyncState == .syncing
    }

    var syncingObservable: Observable<Void> {
        thorChainKit.transactionsSyncStatePublisher.asObservable().map { _ in () }
    }

    var lastBlockInfo: LastBlockInfo? {
        nil
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        .empty()
    }

    var explorerTitle: String {
        thorChainKit.network.chain == .maya ? "MayaScan" : "RuneScan"
    }

    var additionalTokenQueries: [TokenQuery] {
        []
    }

    func explorerUrl(transactionHash: String) -> String? {
        thorChainKit.network.chain == .maya
            ? "https://www.mayascan.org/tx/\(transactionHash)"
            : "https://runescan.io/tx/\(transactionHash)"
    }

    func transactionsObservable(token: Token?, filter: TransactionTypeFilter, address: String?) -> Observable<[TransactionRecord]> {
        thorChainKit.transactionsPublisher
            .asObservable()
            .map { [weak self] in self?.records(from: $0, token: token, filter: filter, address: address) ?? [] }
    }

    func transactionsSingle(paginationData: String?, token: Token?, filter: TransactionTypeFilter, address: String?, limit: Int) -> Single<[TransactionRecord]> {
        // The limit applies to matching records, so it cannot be pushed into the query:
        // one action yields several records and most may be filtered out. Cutting first
        // returns a short page, which the caller reads as "everything is loaded".
        let matching = records(
            from: thorChainKit.transactions(hash: paginationData, descending: true, limit: nil),
            token: token,
            filter: filter,
            address: address
        )

        // The cursor is the last record's transaction, and it excludes that transaction
        // from the next page. Cutting inside one action would therefore drop its
        // remaining records for good — a swap is two records, so the page ends on an
        // action boundary even when that overshoots the limit by one.
        return .just(Self.wholeActions(of: matching, limit: limit))
    }

    private static func wholeActions(of records: [TransactionRecord], limit: Int) -> [TransactionRecord] {
        guard limit > 0, records.count > limit else { return records }
        let boundary = records[limit - 1].transactionHash
        let rest = records.dropFirst(limit).prefix { $0.transactionHash == boundary }
        return Array(records.prefix(limit)) + Array(rest)
    }

    func allTransactionsAfter(paginationData: String?) -> Single<[TransactionRecord]> {
        .just(records(from: thorChainKit.transactions(hash: paginationData, descending: false, limit: nil), token: nil, filter: .all, address: nil))
    }

    func rawTransaction(hash _: String) -> String? {
        nil
    }
}

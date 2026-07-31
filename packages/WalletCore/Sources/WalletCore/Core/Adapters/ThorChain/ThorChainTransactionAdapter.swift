import Combine
import Foundation
import MarketKit
import RxSwift
import ThorChainKit

class ThorChainTransactionsAdapter {
    private let thorChainKitWrapper: ThorChainKitWrapper
    private let converter: ThorChainTransactionConverter

    init(thorChainKitWrapper: ThorChainKitWrapper, source: TransactionSource, baseToken: Token) {
        self.thorChainKitWrapper = thorChainKitWrapper
        converter = ThorChainTransactionConverter(source: source, baseToken: baseToken, thorChainKitWrapper: thorChainKitWrapper)
    }

    private var thorChainKit: ThorChainKit.Kit {
        thorChainKitWrapper.thorChainKit
    }

    private func supports(token: Token?, address: String?) -> Bool {
        if let token {
            guard token.type == .native else { return false }
        }
        return address == nil || address == thorChainKit.address.raw
    }

    private func records(from transactions: [ThorChainKit.Transaction], filter: TransactionTypeFilter) -> [TransactionRecord] {
        let records = transactions.map { converter.transactionRecord(from: $0) }

        switch filter {
        case .all:
            return records
        case .incoming:
            return records.filter { $0 is ThorChainIncomingTransactionRecord }
        case .outgoing:
            return records.filter { $0 is ThorChainOutgoingTransactionRecord }
        default:
            return []
        }
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
        "THORChain"
    }

    var additionalTokenQueries: [TokenQuery] {
        []
    }

    func explorerUrl(transactionHash: String) -> String? {
        "https://thorchain.net/tx/\(transactionHash)"
    }

    func transactionsObservable(token: Token?, filter: TransactionTypeFilter, address: String?) -> Observable<[TransactionRecord]> {
        guard supports(token: token, address: address) else {
            return .just([])
        }

        return thorChainKit.transactionsPublisher
            .asObservable()
            .map { [weak self] in self?.records(from: $0, filter: filter) ?? [] }
    }

    func transactionsSingle(paginationData: String?, token: Token?, filter: TransactionTypeFilter, address: String?, limit: Int) -> Single<[TransactionRecord]> {
        guard supports(token: token, address: address) else {
            return .just([])
        }

        return .just(records(from: thorChainKit.transactions(hash: paginationData, descending: true, limit: limit), filter: filter))
    }

    func allTransactionsAfter(paginationData: String?) -> Single<[TransactionRecord]> {
        .just(records(from: thorChainKit.transactions(hash: paginationData, descending: false, limit: nil), filter: .all))
    }

    func rawTransaction(hash _: String) -> String? {
        nil
    }
}

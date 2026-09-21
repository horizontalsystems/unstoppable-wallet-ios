import Combine
import Foundation
import MarketKit
import RxSwift
import XrpKit

class XrpTransactionAdapter {
    private let xrpKit: XrpKit.Kit
    private let converter: XrpTransactionConverter
    private let spamManager: SpamManager?
    private var cancellables = Set<AnyCancellable>()

    private let adapterStateSubject = PublishSubject<AdapterState>()
    private(set) var adapterState: AdapterState {
        didSet {
            adapterStateSubject.onNext(adapterState)
        }
    }

    init(xrpKit: XrpKit.Kit, source: TransactionSource, baseToken: Token, coinManager: CoinManager, spamWrapper: SpamWrapper) {
        self.xrpKit = xrpKit
        spamManager = spamWrapper.spamManager(source: source)
        converter = XrpTransactionConverter(selfAddress: xrpKit.address, source: source, baseToken: baseToken, coinManager: coinManager)

        adapterState = XrpAdapter.adapterState(kitSyncState: xrpKit.transactionsSyncState)

        xrpKit.transactionsSyncStatePublisher
            .sink { [weak self] in self?.adapterState = XrpAdapter.adapterState(kitSyncState: $0) }
            .store(in: &cancellables)

        spamManager?.initialize(adapter: self)
    }

    private func handleTransactions(_ transactions: [XrpKit.Transaction]) -> [TransactionRecord] {
        let records = transactions.map { converter.transactionRecord(transaction: $0) }

        // Mutates .spam in-place via reference type; keeps the kit's order.
        spamManager?.update(records: records)

        return records
    }

    /// Nil when the filter combination has no matches on XRPL (no swaps or approvals).
    private func tagQuery(token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> TagQuery? {
        let direction: TagQuery.Direction?
        switch filter {
        case .all: direction = nil
        case .incoming: direction = .incoming
        case .outgoing: direction = .outgoing
        default: return nil
        }

        var tokenFilter: TagQuery.Token?
        if let token {
            switch token.type {
            case .native: tokenFilter = .native
            case let .xrpAsset(currency, issuer): tokenFilter = .issued(currency: currency, issuer: issuer)
            default: return nil
            }
        }

        var counterparty: String?
        if let address {
            // history rows hold classic addresses; an X-address resolves to its classic form
            counterparty = XrpKit.Kit.decode(xAddress: address)?.classicAddress ?? (XrpKit.Kit.isValid(address: address) ? address : nil)
            if counterparty == nil {
                return nil
            }
        }

        return TagQuery(direction: direction, token: tokenFilter, address: counterparty)
    }
}

extension XrpTransactionAdapter: ITransactionsAdapter {
    var syncing: Bool {
        adapterState.syncing
    }

    var syncingObservable: Observable<Void> {
        adapterStateSubject.map { _ in () }
    }

    var lastBlockInfo: LastBlockInfo? {
        LastBlockInfo(height: Int(xrpKit.lastLedgerIndex), timestamp: nil)
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        xrpKit.ledgerStatePublisher.map { _ in () }.asObservable()
    }

    var explorerTitle: String {
        "XRPL Explorer"
    }

    var additionalTokenQueries: [TokenQuery] {
        xrpKit.trustLines.map { TokenQuery(blockchainType: .xrp, tokenType: .xrpAsset(currency: $0.currency, issuer: $0.issuer)) }
    }

    func explorerUrl(transactionHash: String) -> String? {
        xrpKit.network.transactionUrl(hash: transactionHash)
    }

    func transactionsObservable(token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> Observable<[TransactionRecord]> {
        guard let tagQuery = tagQuery(token: token, filter: filter, address: address) else {
            return Observable.just([])
        }

        return xrpKit.transactionsPublisher(tagQuery: tagQuery)
            .map { [weak self] in self?.handleTransactions($0) ?? [] }
            .asObservable()
    }

    func transactionsSingle(paginationData: String?, token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?, limit: Int) -> Single<[TransactionRecord]> {
        guard let tagQuery = tagQuery(token: token, filter: filter, address: address) else {
            return Single.just([])
        }

        return Single.create { [weak self, xrpKit] observer in
            Task {
                do {
                    let transactions = try xrpKit.transactions(tagQuery: tagQuery, fromHash: paginationData, limit: limit)
                    observer(.success(self?.handleTransactions(transactions) ?? []))
                } catch {
                    // the kit's store is unreadable: surface it instead of showing an empty history
                    observer(.error(error))
                }
            }

            return Disposables.create()
        }
    }

    func allTransactionsAfter(paginationData: String?) -> Single<[TransactionRecord]> {
        Single.create { [xrpKit, converter] observer in
            Task {
                do {
                    let all = try xrpKit.allTransactions()
                    let anchorTimestamp = paginationData.flatMap { hash in all.first { $0.hash == hash }?.timestamp }
                    let records = all
                        .filter { transaction in anchorTimestamp.map { transaction.timestamp > $0 } ?? true }
                        .map { converter.transactionRecord(transaction: $0) }
                    observer(.success(records))
                } catch {
                    observer(.error(error))
                }
            }

            return Disposables.create()
        }
    }

    func rawTransaction(hash _: String) -> String? {
        nil
    }
}

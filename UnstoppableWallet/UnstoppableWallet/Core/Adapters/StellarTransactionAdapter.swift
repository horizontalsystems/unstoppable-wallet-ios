import BigInt
import Combine
import Foundation
import MarketKit
import RxSwift
import StellarKit

class StellarTransactionAdapter {
    private let stellarKit: StellarKit.Kit
    private let converter: StellarOperationConverter
    private var cancellables = Set<AnyCancellable>()

    private let adapterStateSubject = PublishSubject<AdapterState>()
    private(set) var adapterState: AdapterState {
        didSet {
            adapterStateSubject.onNext(adapterState)
        }
    }

    init(stellarKit: StellarKit.Kit, source: TransactionSource, baseToken: Token, coinManager: CoinManager) {
        self.stellarKit = stellarKit
        converter = StellarOperationConverter(accountId: stellarKit.receiveAddress, source: source, baseToken: baseToken, coinManager: coinManager)

        adapterState = Self.adapterState(kitSyncState: stellarKit.operationSyncState)

        stellarKit.operationSyncStatePublisher
            .sink { [weak self] in self?.adapterState = Self.adapterState(kitSyncState: $0) }
            .store(in: &cancellables)
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
        case .swap: type = .swap
        case .approve: type = .unsupported
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
        case .syncing: return .syncing(progress: nil, lastBlockDate: nil)
        case .synced: return .synced
        case let .notSynced(error): return .notSynced(error: error)
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

    func transactionsObservable(token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> Observable<[TransactionRecord]> {
        stellarKit.operationPublisher(tagQuery: tagQuery(token: token, filter: filter, address: address))
            .asObservable()
            .map { [converter] in
                $0.operations.map { converter.transactionRecord(operation: $0) }
            }
    }

    func transactionsSingle(from: TransactionRecord?, token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?, limit: Int) -> Single<[TransactionRecord]> {
        let tagQuery = tagQuery(token: token, filter: filter, address: address)

        return Single.create { [stellarKit, converter] observer in
            Task { [stellarKit, converter] in
                let pagingToken = (from as? StellarTransactionRecord).map(\.operation.pagingToken)

                let operations = stellarKit.operations(tagQuery: tagQuery, pagingToken: pagingToken, limit: limit)
                let records = operations.map { converter.transactionRecord(operation: $0) }

                observer(.success(records))
            }

            return Disposables.create()
        }
    }

    func rawTransaction(hash _: String) -> String? {
        nil
    }
}

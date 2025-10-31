import BigInt
import Combine
import Foundation
import MarketKit
import RxSwift
import TonKit
import TonSwift

class TonTransactionAdapter {
    private let tonKit: TonKit.Kit
    private let converter: TonEventConverter
    private var cancellables = Set<AnyCancellable>()

    private let adapterStateSubject = PublishSubject<AdapterState>()
    private(set) var adapterState: AdapterState {
        didSet {
            adapterStateSubject.onNext(adapterState)
        }
    }

    init(tonKit: TonKit.Kit, source: TransactionSource, baseToken: Token, coinManager: CoinManager) {
        self.tonKit = tonKit
        converter = TonEventConverter(address: tonKit.receiveAddress, source: source, baseToken: baseToken, coinManager: coinManager)

        adapterState = Self.adapterState(kitSyncState: tonKit.eventSyncState)

        tonKit.eventSyncStatePublisher
            .sink { [weak self] in self?.adapterState = Self.adapterState(kitSyncState: $0) }
            .store(in: &cancellables)
    }

    private func tagQuery(token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> TagQuery {
        var type: Tag.`Type`?
        var platform: Tag.Platform?
        var jettonAddress: TonSwift.Address?

        if let token {
            switch token.type {
            case .native:
                platform = .native
            case let .jetton(address):
                if let address = try? TonSwift.Address.parse(address) {
                    platform = .jetton
                    jettonAddress = address
                }
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

        let address = address.flatMap { try? TonSwift.Address.parse($0) }

        return TagQuery(type: type, platform: platform, jettonAddress: jettonAddress, address: address)
    }

    private static func adapterState(kitSyncState: TonKit.SyncState) -> AdapterState {
        switch kitSyncState {
        case .syncing: return .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
        case .synced: return .synced
        case let .notSynced(error): return .notSynced(error: error.localizedDescription)
        }
    }
}

extension TonTransactionAdapter: ITransactionsAdapter {
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
        "tonviewer.com"
    }

    var additionalTokenQueries: [TokenQuery] {
        tonKit.tagTokens().compactMap { tagToken in
            var tokenType: TokenType?

            switch tagToken.platform {
            case .native:
                tokenType = .native
            case .jetton:
                if let jettonAddress = tagToken.jettonAddress {
                    tokenType = .jetton(address: jettonAddress.toString(testOnly: TonKitManager.isTestNet, bounceable: true))
                }
            }

            guard let tokenType else {
                return nil
            }

            return TokenQuery(blockchainType: .ton, tokenType: tokenType)
        }
    }

    func explorerUrl(transactionHash: String) -> String? {
        "https://tonviewer.com/transaction/\(transactionHash)"
    }

    func transactionsObservable(token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> Observable<[TransactionRecord]> {
        tonKit.eventPublisher(tagQuery: tagQuery(token: token, filter: filter, address: address))
            .asObservable()
            .map { [converter] in
                $0.events.map { converter.transactionRecord(event: $0) }
            }
    }

    func transactionsSingle(paginationData: String?, token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?, limit: Int) -> Single<[TransactionRecord]> {
        let tagQuery = tagQuery(token: token, filter: filter, address: address)

        return Single.create { [tonKit, converter] observer in
            Task { [tonKit, converter] in
                let lt = paginationData.flatMap { Int64($0) }

                let events = tonKit.events(tagQuery: tagQuery, lt: lt, descending: true, limit: limit)
                let records = events.map { converter.transactionRecord(event: $0) }

                observer(.success(records))
            }

            return Disposables.create()
        }
    }

    func allTransactionsAfter(paginationData _: String?) -> Single<[TransactionRecord]> {
        Single.just([])
    }

    func rawTransaction(hash _: String) -> String? {
        nil
    }
}

import BigInt
import Combine
import Foundation
import HdWalletKit
import HsToolKit
import MarketKit
import RxSwift
import TonKit
import TonSwift
import TweetNacl

class TonAdapter {
    private static let coinRate: Decimal = 1_000_000_000
    static let bounceableDefault = false

    private let tonKit: TonKit.Kit
    private let ownAddress: TonSwift.Address
    private let transactionSource: TransactionSource
    private let baseToken: Token
    private let reachabilityManager = App.shared.reachabilityManager
    private let appManager = App.shared.appManager

    private var cancellables = Set<AnyCancellable>()

    private var adapterStarted = false
    private var kitStarted = false

    private let logger: Logger?

    private let adapterStateSubject = PublishSubject<AdapterState>()
    private(set) var adapterState: AdapterState {
        didSet {
            adapterStateSubject.onNext(adapterState)
        }
    }

    private let balanceDataSubject = PublishSubject<BalanceData>()
    private(set) var balanceData: BalanceData {
        didSet {
            balanceDataSubject.onNext(balanceData)
        }
    }

    private let transactionRecordsSubject = PublishSubject<[TonTransactionRecord]>()

    init(wallet: Wallet, baseToken: Token) throws {
        transactionSource = wallet.transactionSource
        self.baseToken = baseToken

//        logger = Logger(minLogLevel: .debug)
        logger = App.shared.logger.scoped(with: "TonKit")

        switch wallet.account.type {
        case .mnemonic:
            guard let seed = wallet.account.type.mnemonicSeed else {
                throw AdapterError.unsupportedAccount
            }

            let hdWallet = HDWallet(seed: seed, coinType: 607, xPrivKey: 0, curve: .ed25519)
            let privateKey = try hdWallet.privateKey(account: 0)
            let privateRaw = Data(privateKey.raw.bytes)
            let pair = try TweetNacl.NaclSign.KeyPair.keyPair(fromSeed: privateRaw)
            let keyPair = KeyPair(publicKey: .init(data: pair.publicKey),
                                  privateKey: .init(data: pair.secretKey))

            tonKit = try Kit.instance(
                type: .full(keyPair),
                network: .mainNet,
                walletId: wallet.account.id,
                apiKey: nil,
                logger: logger
            )

        case let .tonAddress(address):
            let tonAddress = try TonSwift.Address.parse(address)
            tonKit = try Kit.instance(
                type: .watch(tonAddress),
                network: .mainNet,
                walletId: wallet.account.id,
                apiKey: nil,
                logger: logger
            )
        default:
            throw AdapterError.unsupportedAccount
        }

        ownAddress = tonKit.address

        adapterState = Self.adapterState(kitSyncState: tonKit.syncState)
        balanceData = BalanceData(available: Self.amount(kitAmount: tonKit.balance))

        tonKit.syncStatePublisher
            .sink { [weak self] syncState in
                self?.adapterState = Self.adapterState(kitSyncState: syncState)
            }
            .store(in: &cancellables)

        tonKit.tonBalancePublisher
            .sink { [weak self] balance in
                self?.balanceData = BalanceData(available: Self.amount(kitAmount: balance))
            }
            .store(in: &cancellables)

        appManager.didEnterBackgroundPublisher
            .sink { [weak self] in
                self?.stop()
            }
            .store(in: &cancellables)

        appManager.willEnterForegroundPublisher
            .sink { [weak self] in
                self?.start()
            }
            .store(in: &cancellables)
    }

    private func handle(tonTransactions: [TonKit.FullTransaction]) {
        let transactionRecords = tonTransactions.map { transactionRecord(tonTransaction: $0) }
        transactionRecordsSubject.onNext(transactionRecords)
    }

    private static func adapterState(kitSyncState: TonKit.SyncState) -> AdapterState {
        switch kitSyncState {
        case .syncing: return .syncing(progress: nil, lastBlockDate: nil)
        case .synced: return .synced
        case let .notSynced(error): return .notSynced(error: error)
        }
    }

    static func amount(kitAmount: String) -> Decimal {
        Decimal(string: kitAmount).map { amount(kitAmount: $0) } ?? 0
    }

    static func amount(kitAmount: BigUInt) -> Decimal {
        amount(kitAmount: kitAmount.toDecimal(decimals: 0) ?? 0)
    }

    static func amount(kitAmount: Decimal) -> Decimal {
        kitAmount / coinRate
    }

    private func transactionRecord(tonTransaction tx: TonKit.FullTransaction) -> TonTransactionRecord {
        switch tx.decoration {
        case is TonKit.IncomingDecoration:
            return TonIncomingTransactionRecord(
                source: .init(blockchainType: .ton, meta: nil),
                event: tx.event,
                feeToken: baseToken,
                token: baseToken
            )

        case let decoration as TonKit.OutgoingDecoration:
            return TonOutgoingTransactionRecord(
                source: .init(blockchainType: .ton, meta: nil),
                event: tx.event,
                feeToken: baseToken,
                token: baseToken,
                sentToSelf: decoration.sentToSelf
            )

        default:
            return TonTransactionRecord(
                source: .init(blockchainType: .ton, meta: nil),
                event: tx.event,
                feeToken: baseToken
            )
        }
    }

    private func tagQuery(token _: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> TransactionTagQuery {
        var type: TransactionTag.TagType?

        switch filter {
        case .all: ()
        case .incoming: type = .incoming
        case .outgoing: type = .outgoing
        case .swap: type = .swap
        case .approve: type = .approve
        }

        return TransactionTagQuery(type: type, protocol: .native, jettonAddress: nil, address: address)
    }

    private func startKit() {
        logger?.log(level: .debug, message: "TonAdapter, start kit.")
        tonKit.start()
        kitStarted = true
    }

    private func stopKit() {
        logger?.log(level: .debug, message: "TonAdapter, stop kit.")
        tonKit.stop()
        kitStarted = false
    }
}

extension TonAdapter: IBaseAdapter {
    var isMainNet: Bool {
        true
    }
}

extension TonAdapter: IAdapter {
    func start() {
        adapterStarted = true

        if reachabilityManager.isReachable {
            startKit()
        }
    }

    func stop() {
        adapterStarted = false

        if kitStarted {
            stopKit()
        }
    }

    func refresh() {
        tonKit.refresh()
    }

    var statusInfo: [(String, Any)] {
        [] // tonKit.statusInfo()
    }

    var debugInfo: String {
        ""
    }
}

extension TonAdapter: IBalanceAdapter {
    var balanceStateUpdatedObservable: Observable<AdapterState> {
        adapterStateSubject
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        balanceDataSubject.asObservable()
    }

    var balanceState: AdapterState {
        adapterState
    }
}

extension TonAdapter: IDepositAdapter {
    var receiveAddress: DepositAddress {
        DepositAddress(tonKit.receiveAddress.toString(bounceable: TonAdapter.bounceableDefault))
    }
}

extension TonAdapter: ITransactionsAdapter {
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
        "tonscan.org"
    }

    var additionalTokenQueries: [TokenQuery] {
        []
    }

    func explorerUrl(transactionHash: String) -> String? {
        "https://tonscan.org/tx/\(transactionHash)"
    }

    func transactionsObservable(token: Token?, filter: TransactionTypeFilter, address: String?) -> Observable<[TransactionRecord]> {
        let address = address.flatMap { try? FriendlyAddress(string: $0) }?.address.toRaw()

        return tonKit.transactionsPublisher(tagQueries: [tagQuery(token: token, filter: filter, address: address)]).asObservable()
            .map { [weak self] in
                $0.compactMap { self?.transactionRecord(tonTransaction: $0) }
            }
    }

    func transactionsSingle(from: TransactionRecord?, token _: Token?, filter: TransactionTypeFilter, address: String?, limit: Int) -> Single<[TransactionRecord]> {
        Single.create { [weak self] observer in
            guard let self else {
                observer(.error(AppError.unknownError))
                return Disposables.create()
            }

            Task { [weak self] in
                let address = address.flatMap { try? FriendlyAddress(string: $0) }?.address.toRaw()

                let beforeLt = (from as? TonTransactionRecord).map(\.lt)
                var tagQueries = [TransactionTagQuery]()
                switch filter {
                case .all: ()
                case .incoming: tagQueries.append(.init(type: .incoming, address: address))
                case .outgoing: tagQueries.append(.init(type: .outgoing, address: address))
                default: observer(.success([]))
                }

                let txs = (self?.tonKit
                    .transactions(tagQueries: tagQueries, beforeLt: beforeLt, limit: limit)
                    .compactMap { self?.transactionRecord(tonTransaction: $0) }) ?? []

                observer(.success(txs))
            }

            return Disposables.create()
        }
    }

    func rawTransaction(hash _: String) -> String? {
        nil
    }
}

extension TonAdapter: ISendTonAdapter {
    var availableBalance: Decimal {
        balanceData.available
    }

    func validate(address: String) throws {
        _ = try FriendlyAddress(string: address)
    }

    func estimateFee(recipient: String, amount: Decimal, memo: String?) async throws -> Decimal {
        let amount = (amount * Self.coinRate).rounded(decimal: 0)

        let kitAmount = try await tonKit.estimateFee(recipient: recipient, amount: amount, comment: memo)
        return Self.amount(kitAmount: kitAmount)
    }

    func send(recipient: String, amount: Decimal, memo: String?) async throws {
        let amount = (amount * Self.coinRate).rounded(decimal: 0)

        try await tonKit.send(recipient: recipient, amount: amount, comment: memo)
    }
}

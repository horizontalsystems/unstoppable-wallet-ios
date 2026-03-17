import Combine
import Foundation
import HsToolKit
import MarketKit
import RxRelay
import RxSwift
import ZanoKit

class ZanoAdapter {
    static let networkType: ZanoKit.NetworkType = .mainnet
    static let confirmationsThreshold = Int(Kit.confirmationsThreshold)
    static let zanoRate: Decimal = 1_000_000_000_000 // pow(10, 12)

    static let validAddressPrefixes = ["Zx", "aZx", "iZ"]

    private let kit: ZanoKit.Kit
    private let disposeBag = DisposeBag()
    private let queue = DispatchQueue(label: "\(AppConfig.label).zano-adapter", qos: .background)

    private let balanceStateRelay: BehaviorRelay<AdapterState>
    private let balanceDataSubject = PublishSubject<BalanceData>()
    let transactionRecordsSubject = PublishSubject<[ZanoTransactionRecord]>()
    private let depositAddressSubject = PassthroughSubject<DataStatus<DepositAddress>, Never>()

    var balanceState: AdapterState { balanceStateRelay.value }

    let token: Token
    let baseToken: Token // same as token for native ZANO; native ZANO token for confidential assets
    let assetId: String // ZanoAssetId for native ZANO
    let coinRate: Decimal
    private let transactionSource: TransactionSource

    var isNative: Bool { assetId == ZanoAssetId }

    // MARK: – Designated init

    init(kit: ZanoKit.Kit, token: Token, baseToken: Token, assetId: String, coinRate: Decimal, transactionSource: TransactionSource, zanoKitManager: ZanoKitManager) {
        self.kit = kit
        self.token = token
        self.baseToken = baseToken
        self.assetId = assetId
        self.coinRate = coinRate
        self.transactionSource = transactionSource

        balanceStateRelay = BehaviorRelay(value: Self.adapterState(kitState: kit.walletState))

        let scheduler = SerialDispatchQueueScheduler(queue: queue, internalSerialQueueName: "\(AppConfig.label).zano-adapter")

        zanoKitManager.walletStateSubject
            .observeOn(scheduler)
            .subscribe(onNext: { [weak self] state in
                self?.balanceStateRelay.accept(Self.adapterState(kitState: state))
            })
            .disposed(by: disposeBag)

        zanoKitManager.balancesSubject
            .observeOn(scheduler)
            .subscribe(onNext: { [weak self] balances in
                guard let self, let info = balances.first(where: { $0.assetId == self.assetId }) else { return }
                balanceDataSubject.onNext(balanceData(from: info))
            })
            .disposed(by: disposeBag)

        zanoKitManager.transactionsSubject
            .observeOn(scheduler)
            .subscribe(onNext: { [weak self] transactions in
                guard let self else { return }
                let records = transactions.filter { $0.assetId == self.assetId }.map { self.transactionRecord(fromTransaction: $0) }
                if !records.isEmpty {
                    transactionRecordsSubject.onNext(records)
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: – Convenience inits

    convenience init(kit: ZanoKit.Kit, wallet: Wallet, zanoKitManager: ZanoKitManager) {
        self.init(
            kit: kit,
            token: wallet.token,
            baseToken: wallet.token,
            assetId: ZanoAssetId,
            coinRate: Self.zanoRate,
            transactionSource: wallet.transactionSource,
            zanoKitManager: zanoKitManager
        )
    }

    convenience init(kit: ZanoKit.Kit, assetId: String, token: Token, baseToken: Token, transactionSource: TransactionSource, zanoKitManager: ZanoKitManager) {
        self.init(
            kit: kit,
            token: token,
            baseToken: baseToken,
            assetId: assetId,
            coinRate: pow(Decimal(10), token.decimals),
            transactionSource: transactionSource,
            zanoKitManager: zanoKitManager
        )
    }

    // MARK: – Private helpers

    private func balanceData(from info: BalanceInfo) -> BalanceData {
        BalanceData(
            total: Decimal(info.total) / coinRate,
            available: Decimal(info.unlocked) / coinRate
        )
    }

    private func currentBalanceData() -> BalanceData {
        let info: BalanceInfo
        if isNative {
            info = kit.nativeBalance
        } else {
            info = kit.balance(forAssetId: assetId) ?? BalanceInfo(assetId: assetId, total: 0, unlocked: 0)
        }
        return balanceData(from: info)
    }

    func transactionRecord(fromTransaction transaction: TransactionInfo) -> ZanoTransactionRecord {
        let blockHeight = transaction.blockHeight > 0 ? Int(transaction.blockHeight) : nil
        let fee = Decimal(transaction.fee) / Self.zanoRate // fee is always in native ZANO
        let feeToken: Token? = isNative ? nil : baseToken // nil → falls back to token in record init

        switch transaction.type {
        case .outgoing, .sentToSelf:
            return ZanoOutgoingTransactionRecord(
                token: token,
                source: transactionSource,
                uid: transaction.uid,
                transactionHash: transaction.hash,
                transactionIndex: 0,
                blockHeight: blockHeight,
                confirmationsThreshold: Self.confirmationsThreshold,
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                fee: fee,
                failed: transaction.isFailed,
                amount: Decimal(transaction.amount) / coinRate,
                to: transaction.recipientAddress,
                sentToSelf: transaction.type == TransactionType.sentToSelf,
                memo: transaction.memo,
                feeToken: feeToken
            )
        case .incoming:
            return ZanoIncomingTransactionRecord(
                token: token,
                source: transactionSource,
                uid: transaction.uid,
                transactionHash: transaction.hash,
                transactionIndex: 0,
                blockHeight: blockHeight,
                confirmationsThreshold: Self.confirmationsThreshold,
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                fee: fee,
                failed: transaction.isFailed,
                amount: Decimal(transaction.amount) / coinRate,
                from: nil,
                to: transaction.recipientAddress,
                memo: transaction.memo,
                feeToken: feeToken
            )
        }
    }

    static func adapterState(kitState: WalletState) -> AdapterState {
        switch kitState {
        case .connecting:
            return .connecting
        case .synced:
            return .synced
        case let .syncing(progress, remainingBlockCount):
            return .syncing(progress: min(99, progress), remaining: max(1, remainingBlockCount), lastBlockDate: nil)
        case let .notSynced(error):
            return .notSynced(error: error.localizedDescription)
        case .idle:
            return .notSynced(error: AppError.noConnection.localizedDescription)
        }
    }

    var explorerTitle: String { "Zano Explorer" }

    func explorerUrl(transactionHash: String) -> String? {
        "https://explorer.zano.org/transaction/\(transactionHash)"
    }

    func explorerUrl(address _: String) -> String? { "" }
}

extension ZanoAdapter: IAdapter {
    var isMainNet: Bool { true }
    var debugInfo: String { "" }

    func start() { /* started by ZanoKitManager */ }
    func stop() { /* lifecycle managed via deallocation of the kit */ }
    func refresh() { /* called in AdapterManager */ }
    func restart() { /* called in AdapterManager */ }

    var statusInfo: [(String, Any)] { kit.statusInfo }
}

extension ZanoAdapter: IBalanceAdapter {
    var balanceStateUpdatedObservable: Observable<AdapterState> {
        balanceStateRelay.asObservable()
    }

    var balanceData: BalanceData {
        currentBalanceData()
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        balanceDataSubject.asObservable()
    }
}

extension ZanoAdapter: ITransactionsAdapter {
    func rawTransaction(hash _: String) -> String? { nil }

    var syncing: Bool { balanceState.syncing }

    var lastBlockInfo: LastBlockInfo? {
        LastBlockInfo(height: Int(kit.lastBlockInfo), timestamp: nil)
    }

    var syncingObservable: Observable<Void> {
        balanceStateRelay.asObservable().map { _ in () }
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        balanceStateRelay.asObservable().map { _ in () }
    }

    var additionalTokenQueries: [TokenQuery] { [] }

    func transactionsObservable(token _: Token?, filter: TransactionTypeFilter, address _: String?) -> Observable<[TransactionRecord]> {
        transactionRecordsSubject.asObservable()
            .map { transactions in
                transactions.compactMap { transaction -> TransactionRecord? in
                    switch (transaction, filter) {
                    case (_, .all): return transaction
                    case (is ZanoIncomingTransactionRecord, .incoming): return transaction
                    case (is ZanoOutgoingTransactionRecord, .outgoing): return transaction
                    case let (tx as ZanoOutgoingTransactionRecord, .incoming): return tx.sentToSelf ? transaction : nil
                    default: return nil
                    }
                }
            }
            .filter { !$0.isEmpty }
    }

    func transactionsSingle(paginationData: String?, token _: Token?, filter: TransactionTypeFilter, address _: String?, limit: Int) -> Single<[TransactionRecord]> {
        let zanoFilter: TransactionFilterType?
        switch filter {
        case .all: zanoFilter = nil
        case .incoming: zanoFilter = .incoming
        case .outgoing: zanoFilter = .outgoing
        default: return Single.just([])
        }

        let transactions = kit.transactions(assetId: assetId, fromHash: paginationData, descending: true, type: zanoFilter, limit: limit).map {
            transactionRecord(fromTransaction: $0)
        }

        return Single.just(transactions)
    }

    func allTransactionsAfter(paginationData _: String?) -> Single<[TransactionRecord]> {
        Single.just([])
    }
}

extension ZanoAdapter: IDepositAdapter {
    var receiveAddress: DepositAddress {
        DepositAddress(kit.receiveAddress)
    }

    var receiveAddressPublisher: AnyPublisher<DataStatus<DepositAddress>, Never> {
        depositAddressSubject.eraseToAnyPublisher()
    }

    var usedAddresses: [UsedAddress] { [] }
}

extension ZanoAdapter {
    var minimumSendAmount: Decimal { 0.0 }

    func estimateFee() -> Decimal {
        Decimal(kit.estimateFee(priority: .default)) / Self.zanoRate
    }

    func send(to address: String, amount: ZanoSendAmount, memo: String?) throws {
        _ = try kit.send(to: address, assetId: assetId, amount: convertToAtomic(amount: amount), priority: .default, memo: memo)
    }

    func convertToAtomic(amount: ZanoSendAmount) -> SendAmount {
        switch amount {
        case .all:
            return .all
        case let .value(value):
            let coinValue: Decimal = value * coinRate
            let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: Int16(truncatingIfNeeded: 0), raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
            let atomicValue = NSDecimalNumber(decimal: coinValue).rounding(accordingToBehavior: handler).intValue
            return .value(atomicValue)
        }
    }
}

extension ZanoAdapter {
    static func clear(except excludedWalletIds: [String]) throws {
        try Kit.removeAll(except: excludedWalletIds)
    }

    static func isValidAddress(_ address: String) -> Bool {
        let hasPrefix = validAddressPrefixes.contains { prefix in
            address.lowercased().hasPrefix(prefix.lowercased())
        }

        guard hasPrefix else {
            return false
        }

        return Kit.isValid(address: address, networkType: networkType)
    }

    static func address(accountType: AccountType) -> String {
        switch accountType {
        case let .mnemonic(words, passphrase, _):
            return (try? Kit.address(wallet: .bip39(seed: words, passphrase: passphrase, creationTimestamp: 0))) ?? ""

        default: return ""
        }
    }
}

enum ZanoSendAmount {
    case value(Decimal)
    case all(Decimal)

    var value: Decimal {
        switch self {
        case let .all(value): return value
        case let .value(value): return value
        }
    }
}

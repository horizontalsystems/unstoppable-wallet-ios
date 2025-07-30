import Foundation
import HdWalletKit
import HsToolKit
import MarketKit
import MoneroKit
import RxSwift

class MoneroAdapter {
    private static let networkType: MoneroKit.NetworkType = .mainnet
    static let confirmationsThreshold = 1
    static let txStatusConfirmationsThreshold = 3

    var coinRate: Decimal { 1_000_000_000_000 } // pow(10, 12)

    private let kit: MoneroKit.Kit
    private let daemonAddress: String = "xmr-node.cakewallet.com:18081"
    private let moneroBalanceDataSubject = PublishSubject<MoneroBalanceData>()
    private let lastBlockUpdatedSubject = PublishSubject<Void>()
    private let balanceStateSubject = PublishSubject<AdapterState>()
    let transactionRecordsSubject = PublishSubject<[BitcoinTransactionRecord]>()

    private(set) var balanceState: AdapterState {
        didSet {
            balanceStateSubject.onNext(balanceState)
            syncing = balanceState.syncing
        }
    }

    private(set) var syncing: Bool = true

    let token: Token
    private let transactionSource: TransactionSource

    init(wallet: Wallet, restoreSettings: RestoreSettings) throws {
        switch wallet.account.type {
        case let .mnemonic(words, passphrase, _):
            kit = try MoneroKit.Kit(
                mnemonic: .bip39(seed: words, passphrase: passphrase),
                restoreHeight: UInt64(restoreSettings.birthdayHeight ?? 0),
                walletId: wallet.account.id,
                daemonAddress: daemonAddress,
                networkType: Self.networkType
            )
        default:
            throw AdapterError.unsupportedAccount
        }

        token = wallet.token
        transactionSource = wallet.transactionSource

        balanceState = .notSynced(error: AppError.unknownError)
        kit.delegate = self
    }

    func transactionRecord(fromTransaction transaction: TransactionInfo) -> BitcoinTransactionRecord {
        switch transaction.type {
        case .outgoing, .sentToSelf:
            return BitcoinOutgoingTransactionRecord(
                token: token,
                source: transactionSource,
                uid: transaction.uid,
                transactionHash: transaction.hash,
                transactionIndex: 0,
                blockHeight: Int(transaction.blockHeight),
                confirmationsThreshold: Self.confirmationsThreshold,
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                fee: Decimal(transaction.fee) / coinRate,
                failed: transaction.isFailed,
                lockInfo: nil,
                conflictingHash: nil,
                showRawTransaction: false,
                amount: Decimal(transaction.amount) / coinRate,
                to: transaction.recipientAddress,
                sentToSelf: transaction.type == TransactionType.sentToSelf,
                memo: nil,
                replaceable: false
            )
        case .incoming:
            return BitcoinIncomingTransactionRecord(
                token: token,
                source: transactionSource,
                uid: transaction.uid,
                transactionHash: transaction.hash,
                transactionIndex: 0,
                blockHeight: Int(transaction.blockHeight),
                confirmationsThreshold: Self.confirmationsThreshold,
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                fee: Decimal(transaction.fee) / coinRate,
                failed: transaction.isFailed,
                lockInfo: nil,
                conflictingHash: nil,
                showRawTransaction: false,
                amount: Decimal(transaction.amount) / coinRate,
                from: nil,
                memo: nil
            )
        }
    }

    private func moneroBalanceData(balanceInfo: BalanceInfo) -> MoneroBalanceData {
        MoneroBalanceData(
            all: Decimal(balanceInfo.all) / coinRate,
            unspendable: Decimal(balanceInfo.unspendable) / coinRate
        )
    }

    private func adapterStateFromKit() -> AdapterState {
        if kit.isSynchronized {
            return .synced
        }

        switch kit.walletStatus {
            case .ok, .unknown:
                if let daemonHeight = kit.daemonHeight, let lastBlockHeight = kit.lastBlockHeight {
                    if daemonHeight > lastBlockHeight {
                        return .syncing(progress: lastBlockHeight * 100 / daemonHeight, lastBlockDate: nil)
                    } else {
                        return .synced
                    }
                } else {
                    return .syncing(progress: 0, lastBlockDate: nil)
                }
            case .error(let error):
                return .notSynced(error: error ?? AppError.unknownError)
            case .critical(let error):
                return .notSynced(error: error ?? AppError.unknownError)
        }
    }

    public var explorerTitle: String {
        "Blockchair"
    }

    public func explorerUrl(transactionHash: String) -> String? {
        "https://blockchair.com/monero/transaction/\(transactionHash)"
    }

    public func explorerUrl(address _: String) -> String? {
        ""
    }
}

extension MoneroAdapter: IAdapter {
    var isMainNet: Bool {
        true
    }

    var debugInfo: String {
        ""
    }

    func start() {
        balanceState = .syncing(progress: 0, lastBlockDate: nil)
        kit.start()
    }

    func stop() {
        kit.stop()
    }

    func refresh() {
        kit.start()
    }

    var statusInfo: [(String, Any)] {
        []
    }
}

extension MoneroAdapter: MoneroKitDelegate {
    func balanceDidChange(balanceInfo: MoneroKit.BalanceInfo) {
        moneroBalanceDataSubject.onNext(moneroBalanceData(balanceInfo: balanceInfo))
    }

    func walletStatusDidChange(status: MoneroKit.WalletStatus) {
        balanceState = adapterStateFromKit()
    }

    func syncStateDidChange(isSynchronized _: Bool) {
        balanceState = adapterStateFromKit()
    }

    func lastBlockHeightDidChange(height _: UInt64) {
        balanceState = adapterStateFromKit()
        lastBlockUpdatedSubject.onNext(())
    }

    func transactionsUpdated(inserted: [TransactionInfo], updated: [TransactionInfo]) {
        var records = [BitcoinTransactionRecord]()

        for info in inserted {
            records.append(transactionRecord(fromTransaction: info))
        }
        for info in updated {
            records.append(transactionRecord(fromTransaction: info))
        }

        transactionRecordsSubject.onNext(records)
    }
}

extension MoneroAdapter: IBalanceAdapter {
    var balanceStateUpdatedObservable: Observable<AdapterState> {
        balanceStateSubject.asObservable()
    }

    var balanceData: BalanceData {
        moneroBalanceData.balanceData
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        moneroBalanceDataSubject.map(\.balanceData).asObservable()
    }
}

extension MoneroAdapter {
    var moneroBalanceData: MoneroBalanceData {
        moneroBalanceData(balanceInfo: kit.balanceInfo)
    }

    var moneroBalanceDataObservable: Observable<MoneroBalanceData> {
        moneroBalanceDataSubject.asObservable()
    }

    var minimumSendAmount: Decimal {
        0.0
    }

    func validate(address: String) -> Bool {
        kit.validate(address: address)
    }

    func estimateFee(amount: Int) throws -> Int {
        Int(kit.estimateFee(amount: amount))
    }

    func send(to address: String, amount: Int) throws {
        _ = try kit.send(to: address, amount: amount)
    }

    func convertToSatoshi(value: Decimal) -> Int {
        let coinValue: Decimal = value * coinRate
        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: Int16(truncatingIfNeeded: 0), raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        return NSDecimalNumber(decimal: coinValue).rounding(accordingToBehavior: handler).intValue
    }
}

extension MoneroAdapter: ITransactionsAdapter {
    func rawTransaction(hash _: String) -> String? {
        nil
    }

    var lastBlockInfo: LastBlockInfo? {
        kit.lastBlockHeight.map { LastBlockInfo(height: $0, timestamp: nil) }
    }

    var syncingObservable: Observable<Void> {
        balanceStateSubject.map { _ in () }
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        lastBlockUpdatedSubject.asObservable()
    }

    var additionalTokenQueries: [TokenQuery] {
        []
    }

    func transactionsObservable(token _: Token?, filter: TransactionTypeFilter, address _: String?) -> Observable<[TransactionRecord]> {
        transactionRecordsSubject.asObservable()
            .map { transactions in
                transactions.compactMap { transaction -> TransactionRecord? in
                    switch (transaction, filter) {
                    case (_, .all): return transaction
                    case (is BitcoinIncomingTransactionRecord, .incoming): return transaction
                    case (is BitcoinOutgoingTransactionRecord, .outgoing): return transaction
                    case let (tx as BitcoinOutgoingTransactionRecord, .incoming): return tx.sentToSelf ? transaction : nil
                    default: return nil
                    }
                }
            }
            .filter { !$0.isEmpty }
    }

    func transactionsSingle(paginationData: String?, token _: Token?, filter: TransactionTypeFilter, address _: String?, limit: Int) -> Single<[TransactionRecord]> {
        let bitcoinFilter: TransactionFilterType?
        switch filter {
        case .all: bitcoinFilter = nil
        case .incoming: bitcoinFilter = .incoming
        case .outgoing: bitcoinFilter = .outgoing
        default: return Single.just([])
        }

        let transactions = kit.transactions(fromUid: paginationData, type: bitcoinFilter, limit: limit).map {
            transactionRecord(fromTransaction: $0)
        }

        return Single.just(transactions)
    }

    func allTransactionsAfter(paginationData _: String?) -> Single<[TransactionRecord]> {
        Single.just([])
    }
}

extension MoneroAdapter: IDepositAdapter {
    var receiveAddress: DepositAddress {
        DepositAddress(kit.receiveAddress)
    }

    func usedAddresses(change _: Bool) -> [UsedAddress] {
        []
//        kit.usedAddresses(change: change).map {
//            let url = explorerUrl(address: $0.address).flatMap { URL(string: $0) }
//            return UsedAddress(index: $0.index, address: $0.address, explorerUrl: url)
//        }.sorted { $0.index < $1.index }
    }
}

extension MoneroAdapter {
    struct MoneroBalanceData {
        let all: Decimal
        let unspendable: Decimal

        var balanceData: BalanceData {
            BalanceData(total: all, available: all - unspendable)
        }
    }
}

import RxSwift
import BinanceChainKit

class BinanceAdapter {
    private static let confirmationsThreshold = 1
    static let transferFee: Decimal = 0.000375

    private let binanceKit: BinanceChainKit
    private let asset: Asset

    init(binanceKit: BinanceChainKit, symbol: String) {
        self.binanceKit = binanceKit

        asset = binanceKit.register(symbol: symbol)
    }

    private func transactionRecord(fromTransaction transaction: TransactionInfo) -> TransactionRecord {
        let type: TransactionType
        let fromMine = transaction.from == binanceKit.account
        let toMine = transaction.to == binanceKit.account

        if fromMine && !toMine {
            type = .outgoing
        } else if !fromMine && toMine {
            type = .incoming
        } else {
            type = .sentToSelf
        }

        return TransactionRecord(
                uid: transaction.hash,
                transactionHash: transaction.hash,
                transactionIndex: 0,
                interTransactionIndex: 0,
                type: type,
                blockHeight: transaction.blockHeight,
                confirmationsThreshold: Self.confirmationsThreshold,
                amount: transaction.amount,
                fee: BinanceAdapter.transferFee,
                date: transaction.date,
                failed: false,
                from: transaction.from,
                to: transaction.to,
                lockInfo: nil,
                conflictingHash: nil,
                showRawTransaction: false,
                memo: transaction.memo
        )
    }

}

extension BinanceAdapter {
    //todo: Make binanceKit errors public!
    enum AddressConversion: Error {
        case invalidAddress
    }

    static func clear(except excludedWalletIds: [String]) throws {
        try BinanceChainKit.clear(exceptFor: excludedWalletIds)
    }

}

extension BinanceAdapter: IAdapter {

    func start() {
        // started via BinanceKitManager
    }

    func stop() {
        // stopped via BinanceKitManager
    }

    func refresh() {
        // refreshed via BinanceKitManager
    }

    var debugInfo: String {
        ""
    }

}

extension BinanceAdapter: IBalanceAdapter {

    var balanceState: AdapterState {
        switch binanceKit.syncState {
        case .synced: return .synced
        case .notSynced(let error): return .notSynced(error: error.convertedError)
        case .syncing: return .syncing(progress: 50, lastBlockDate: nil)
        }
    }

    var balanceStateUpdatedObservable: Observable<Void> {
        binanceKit.syncStateObservable.map { _ in () }
    }

    var balance: Decimal {
        asset.balance
    }

    var balanceUpdatedObservable: Observable<Void> {
        asset.balanceObservable.map { _ in () }
    }

}

extension BinanceAdapter: ISendBinanceAdapter {

    var availableBalance: Decimal {
        var balance = asset.balance
        if asset.symbol == "BNB" {
            balance -= BinanceAdapter.transferFee
        }
        return max(0, balance)
    }

    var availableBinanceBalance: Decimal {
        binanceKit.binanceBalance
    }

    func validate(address: String) throws {
        //todo: remove when make errors public
        do {
            try binanceKit.validate(address: address)
        } catch {
            throw AddressConversion.invalidAddress
        }
    }

    var fee: Decimal {
        BinanceAdapter.transferFee
    }

    func sendSingle(amount: Decimal, address: String, memo: String?) -> Single<Void> {
        binanceKit.sendSingle(symbol: asset.symbol, to: address, amount: amount, memo: memo ?? "")
                .map { _ in () }
    }

}

extension BinanceAdapter: ITransactionsAdapter {

    var transactionState: AdapterState {
        switch binanceKit.syncState {
            case .synced: return .synced
            case .notSynced(let error): return .notSynced(error: error.convertedError)
            case .syncing: return .syncing(progress: 50, lastBlockDate: nil)
        }
    }

    var lastBlockInfo: LastBlockInfo? {
        binanceKit.lastBlockHeight.map { LastBlockInfo(height: $0, timestamp: nil) }
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        binanceKit.lastBlockHeightObservable.map { _ in () }
    }

    var transactionStateUpdatedObservable: Observable<Void> {
        binanceKit.syncStateObservable.map { _ in () }
    }

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        asset.transactionsObservable.map { [weak self] in
            $0.compactMap {
                self?.transactionRecord(fromTransaction: $0)
            }
        }
    }

    func transactionsSingle(from: TransactionRecord?, limit: Int) -> Single<[TransactionRecord]> {
        binanceKit.transactionsSingle(symbol: asset.symbol, fromTransactionHash: from?.transactionHash, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    transactions.compactMap { self?.transactionRecord(fromTransaction: $0) }
                }
    }

    func rawTransaction(hash: String) -> String? {
        nil
    }

}

extension BinanceAdapter: IDepositAdapter {

    var receiveAddress: String {
        binanceKit.account
    }

}

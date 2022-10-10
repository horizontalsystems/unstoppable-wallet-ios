import Foundation
import RxSwift
import BinanceChainKit
import MarketKit

class BinanceAdapter {
    static let confirmationsThreshold = 1
    static let transferFee: Decimal = 0.000075

    private let binanceKit: BinanceChainKit
    private let feeToken: Token
    private let token: Token
    private let asset: Asset
    private let transactionSource: TransactionSource

    init(binanceKit: BinanceChainKit, feeToken: Token, wallet: Wallet) {
        self.binanceKit = binanceKit
        self.feeToken = feeToken
        token = wallet.token
        transactionSource = wallet.transactionSource

        let symbol: String

        switch token.type {
        case .bep2(let value): symbol = value
        default: symbol = "BNB"
        }

        asset = binanceKit.register(symbol: symbol)
    }

    private func transactionRecord(fromTransaction transaction: TransactionInfo) -> TransactionRecord {
        let fromMine = transaction.from == binanceKit.account
        let toMine = transaction.to == binanceKit.account

        if fromMine && !toMine {
            return BinanceChainOutgoingTransactionRecord(source: transactionSource, transaction: transaction, feeToken: feeToken, token: token, sentToSelf: false)
        } else if !fromMine && toMine {
            return BinanceChainIncomingTransactionRecord(source: transactionSource, transaction: transaction, feeToken: feeToken, token: token)
        } else {
            return BinanceChainOutgoingTransactionRecord(source: transactionSource, transaction: transaction, feeToken: feeToken, token: token, sentToSelf: true)
        }
    }

    private func adapterState(syncState: BinanceChainKit.SyncState) -> AdapterState {
        switch syncState {
        case .synced: return .synced
        case .notSynced(let error): return .notSynced(error: error.convertedError)
        case .syncing: return .syncing(progress: nil, lastBlockDate: nil)
        }
    }

    private func balanceInfo(balance: Decimal) -> BalanceData {
        BalanceData(balance: balance)
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

    var isMainNet: Bool {
        true
    }

    func start() {
        // started via BinanceKitManager
    }

    func stop() {
        // stopped via BinanceKitManager
    }

    func refresh() {
        binanceKit.refresh()
    }

    var statusInfo: [(String, Any)] {
        binanceKit.statusInfo
    }

    var debugInfo: String {
        ""
    }

}

extension BinanceAdapter: IBalanceAdapter {

    var balanceState: AdapterState {
        adapterState(syncState: binanceKit.syncState)
    }

    var balanceStateUpdatedObservable: Observable<AdapterState> {
        binanceKit.syncStateObservable.map { [weak self] in
            self?.adapterState(syncState: $0) ?? .syncing(progress: nil, lastBlockDate: nil)
        }
    }

    var balanceData: BalanceData {
        balanceInfo(balance: asset.balance)
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        asset.balanceObservable.map { [weak self] in
            self?.balanceInfo(balance: $0) ?? BalanceData(balance: 0)
        }
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

    var syncing: Bool {
        if case .syncing = binanceKit.syncState { return true }
        return false
    }

    var lastBlockInfo: LastBlockInfo? {
        binanceKit.lastBlockHeight.map { LastBlockInfo(height: $0, timestamp: nil) }
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        binanceKit.lastBlockHeightObservable.map { _ in () }
    }

    var syncingObservable: Observable<Void> {
        binanceKit.syncStateObservable.map { _ in () }
    }

    var explorerTitle: String {
        "binance.org"
    }

    func explorerUrl(transactionHash: String) -> String? {
        binanceKit.networkType == .mainNet
                ? "https://explorer.binance.org/tx/" + transactionHash
                : "https://testnet-explorer.binance.org/tx/" + transactionHash
    }

    func transactionsObservable(token: Token?, filter: TransactionTypeFilter) -> Observable<[TransactionRecord]> {
        let binanceChainFilter: TransactionFilterType?
        switch filter {
            case .all: binanceChainFilter = nil
            case .incoming: binanceChainFilter = .incoming
            case .outgoing: binanceChainFilter = .outgoing
            default: return Observable.just([])
        }

        return asset.transactionsObservable(filterType: binanceChainFilter).map { [weak self] in
            $0.compactMap {
                self?.transactionRecord(fromTransaction: $0)
            }
        }
    }

    func transactionsSingle(from: TransactionRecord?, token: Token?, filter: TransactionTypeFilter, limit: Int) -> Single<[TransactionRecord]> {
        let binanceChainFilter: TransactionFilterType?

        switch filter {
            case .all: binanceChainFilter = nil
            case .incoming: binanceChainFilter = .incoming
            case .outgoing: binanceChainFilter = .outgoing
            default: return Single.just([])
        }

        return binanceKit.transactionsSingle(symbol: asset.symbol, filterType: binanceChainFilter, fromTransactionHash: from?.transactionHash, limit: limit)
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

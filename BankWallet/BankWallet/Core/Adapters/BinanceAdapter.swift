import RxSwift
import BinanceChainKit

class BinanceAdapter {
    private let binanceKit: BinanceChainKit
    private let asset: Asset

    let wallet: Wallet
    let decimal: Int = 8

    init(wallet: Wallet, binanceKit: BinanceChainKit, symbol: String) {
        self.wallet = wallet
        self.binanceKit = binanceKit

        asset = binanceKit.register(symbol: symbol)
    }

    private func transactionRecord(fromTransaction transaction: TransactionInfo) -> TransactionRecord {
        let from = TransactionAddress(
                address: transaction.from,
                mine: transaction.from == binanceKit.account
        )

        let to = TransactionAddress(
                address: transaction.to,
                mine: transaction.to == binanceKit.account
        )

        return TransactionRecord(
                transactionHash: transaction.hash,
                transactionIndex: 0,
                interTransactionIndex: 0,
                blockHeight: transaction.blockNumber,
                amount: transaction.amount * (from.mine ? -1 : 1),
                date: transaction.date,
                from: [from],
                to: [to]
        )
    }

}

extension BinanceAdapter: IAdapter {

    var confirmationsThreshold: Int {
        // todo: set correct value
        return 6
    }

    var refreshable: Bool {
        return true
    }

    func start() {
        // started via BinanceKitManager
    }

    func stop() {
        // stopped via BinanceKitManager
    }

    func refresh() {
        // refreshed via BinanceKitManager
    }

    var lastBlockHeight: Int? {
        return binanceKit.latestBlockHeight
    }

    var lastBlockHeightUpdatedObservable: Observable<Void> {
        return binanceKit.lastBlockHeightObservable.map { _ in () }
    }

    var state: AdapterState {
        switch binanceKit.syncState {
        case .synced: return .synced
        case .notSynced: return .notSynced
        case .syncing: return .syncing(progress: 50, lastBlockDate: nil)
        }
    }

    var stateUpdatedObservable: Observable<Void> {
        return binanceKit.syncStateObservable.map { _ in () }
    }

    var balance: Decimal {
        return asset.balance
    }

    var balanceUpdatedObservable: Observable<Void> {
        return asset.balanceObservable.map { _ in () }
    }

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        return asset.transactionsObservable.map { [weak self] in
            $0.compactMap {
                self?.transactionRecord(fromTransaction: $0)
            }
        }
    }

    func transactionsSingle(from: (hash: String, interTransactionIndex: Int)?, limit: Int) -> Single<[TransactionRecord]> {
        return binanceKit.transactionsSingle(symbol: asset.symbol, fromTransactionHash: from?.hash, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    return transactions.compactMap { self?.transactionRecord(fromTransaction: $0) }
                }
    }

    func sendSingle(params: [String : Any]) -> Single<Void> {
        guard let amount: Decimal = params[AdapterField.amount.rawValue] as? Decimal,
              let address: String = params[AdapterField.address.rawValue] as? String else {
            return Single.error(AdapterError.wrongParameters)
        }
        let memo: String? = params[AdapterField.memo.rawValue] as? String
        return binanceKit.sendSingle(symbol: asset.symbol, to: address, amount: amount, memo: memo ?? "from Unstoppable Wallet")
                .map { _ in () }
    }

    func availableBalance(params: [String : Any]) -> Decimal {
        // todo
        return asset.balance
    }

    func fee(params: [String : Any]) -> Decimal {
        // todo
        return 0
    }

    func validate(address: String) throws {
        // todo
    }

    func validate(params: [String : Any]) -> [SendStateError] {
        // todo
        return []
    }

    func parse(paymentAddress: String) -> PaymentRequestAddress {
        return PaymentRequestAddress(address: paymentAddress, amount: nil)
    }

    var receiveAddress: String {
        return binanceKit.account
    }

    var debugInfo: String {
        return ""
    }

}

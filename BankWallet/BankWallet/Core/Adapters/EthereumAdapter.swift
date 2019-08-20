import EthereumKit
import RxSwift

class EthereumAdapter: EthereumBaseAdapter {
    static let decimal = 18

    init(ethereumKit: EthereumKit) {
        super.init(ethereumKit: ethereumKit, decimal: EthereumAdapter.decimal)
    }

    private func transactionRecord(fromTransaction transaction: TransactionInfo) -> TransactionRecord {
        let mineAddress = ethereumKit.receiveAddress.lowercased()

        let from = TransactionAddress(
                address: transaction.from,
                mine: transaction.from.lowercased() == mineAddress
        )

        let to = TransactionAddress(
                address: transaction.to,
                mine: transaction.to.lowercased() == mineAddress
        )

        var amount: Decimal = 0

        if let significand = Decimal(string: transaction.value) {
            let sign: FloatingPointSign = from.mine ? .minus : .plus
            amount = Decimal(sign: sign, exponent: -decimal, significand: significand)
        }

        return TransactionRecord(
                transactionHash: transaction.hash,
                transactionIndex: transaction.transactionIndex ?? 0,
                interTransactionIndex: 0,
                blockHeight: transaction.blockNumber,
                amount: amount,
                date: Date(timeIntervalSince1970: transaction.timestamp),
                from: [from],
                to: [to]
        )
    }

    override func sendSingle(to address: String, value: String, gasPrice: Int) -> Single<Void> {
        return ethereumKit.sendSingle(to: address, value: value, gasPrice: gasPrice)
                .map { _ in ()}
                .catchError { [weak self] error in
                    return Single.error(self?.createSendError(from: error) ?? error)
                }
    }

}

extension EthereumAdapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try EthereumKit.clear(exceptFor: excludedWalletIds)
    }

}

extension EthereumAdapter: IBalanceAdapter {

    var state: AdapterState {
        switch ethereumKit.syncState {
        case .synced: return .synced
        case .notSynced: return .notSynced
        case .syncing: return .syncing(progress: 50, lastBlockDate: nil)
        }
    }

    var stateUpdatedObservable: Observable<Void> {
        return ethereumKit.syncStateObservable.map { _ in () }
    }

    var balance: Decimal {
        return balanceDecimal(balanceString: ethereumKit.balance, decimal: EthereumAdapter.decimal)
    }

    var balanceUpdatedObservable: Observable<Void> {
        return ethereumKit.balanceObservable.map { _ in () }
    }

}

extension EthereumAdapter: ISendEthereumAdapter {

    func availableBalance(gasPrice: Int) -> Decimal {
        return max(0, balance - fee(gasPrice: gasPrice))
    }

    var ethereumBalance: Decimal {
        return balance
    }

    func fee(gasPrice: Int) -> Decimal {
        return ethereumKit.fee(gasPrice: gasPrice) / pow(10, EthereumAdapter.decimal)
    }

}

extension EthereumAdapter: ITransactionsAdapter {

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        return ethereumKit.transactionsObservable.map { [weak self] in
            $0.compactMap { self?.transactionRecord(fromTransaction: $0) }
        }
    }

    func transactionsSingle(from: (hash: String, interTransactionIndex: Int)?, limit: Int) -> Single<[TransactionRecord]> {
        return ethereumKit.transactionsSingle(fromHash: from?.hash, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    return transactions.compactMap { self?.transactionRecord(fromTransaction: $0) }
                }
    }

}

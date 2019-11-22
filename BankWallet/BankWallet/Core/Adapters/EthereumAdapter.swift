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
            let transactionAmount = Decimal(sign: .plus, exponent: -decimal, significand: significand)

            if from.mine {
                amount -= transactionAmount
            }
            if to.mine {
                amount += transactionAmount
            }
        }

        return TransactionRecord(
                transactionHash: transaction.hash,
                transactionIndex: transaction.transactionIndex ?? 0,
                interTransactionIndex: 0,
                blockHeight: transaction.blockNumber,
                amount: amount,
                fee: transaction.gasUsed.map { Decimal(sign: .plus, exponent: -decimal, significand: Decimal($0 * transaction.gasPrice)) },
                date: Date(timeIntervalSince1970: transaction.timestamp),
                from: [from],
                to: [to]
        )
    }

    override func sendSingle(to address: String, value: String, gasPrice: Int, gasLimit: Int) -> Single<Void> {
        ethereumKit.sendSingle(to: address, value: value, gasPrice: gasPrice, gasLimit: gasLimit)
                .map { _ in ()}
                .catchError { [weak self] error in
                    Single.error(self?.createSendError(from: error) ?? error)
                }
    }

    override func estimateGasLimit(to address: String, value: Decimal, gasPrice: Int?) -> Single<Int> {
        Single.just(ethereumKit.gasLimit)
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
        ethereumKit.syncStateObservable.map { _ in () }
    }

    var balance: Decimal {
        balanceDecimal(balanceString: ethereumKit.balance, decimal: EthereumAdapter.decimal)
    }

    var balanceUpdatedObservable: Observable<Void> {
        ethereumKit.balanceObservable.map { _ in () }
    }

}

extension EthereumAdapter: ISendEthereumAdapter {

    func availableBalance(gasPrice: Int, gasLimit: Int?) -> Decimal {
        guard let gasLimit = gasLimit else {
            return balance
        }
        return max(0, balance - fee(gasPrice: gasPrice, gasLimit: gasLimit))
    }

    var ethereumBalance: Decimal {
        balance
    }

    var minimumRequiredBalance: Decimal {
        0
    }

    func fee(gasPrice: Int, gasLimit: Int) -> Decimal {
        ethereumKit.fee(gasPrice: gasPrice) / pow(10, EthereumAdapter.decimal)
    }

}

extension EthereumAdapter: ITransactionsAdapter {

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        ethereumKit.transactionsObservable.map { [weak self] in
            $0.compactMap { self?.transactionRecord(fromTransaction: $0) }
        }
    }

    func transactionsSingle(from: (hash: String, interTransactionIndex: Int)?, limit: Int) -> Single<[TransactionRecord]> {
        ethereumKit.transactionsSingle(fromHash: from?.hash, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    transactions.compactMap { self?.transactionRecord(fromTransaction: $0) }
                }
    }

}

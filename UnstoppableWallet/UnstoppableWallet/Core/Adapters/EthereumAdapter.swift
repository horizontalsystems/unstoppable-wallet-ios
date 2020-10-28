import EthereumKit
import RxSwift
import BigInt
import HsToolKit

class EthereumAdapter: EthereumBaseAdapter {
    static let decimal = 18

    init(ethereumKit: EthereumKit.Kit) {
        super.init(ethereumKit: ethereumKit, decimal: EthereumAdapter.decimal)
    }

    private func convertAmount(amount: BigUInt, fromAddress: Address) -> Decimal {
        guard let significand = Decimal(string: amount.description), significand != 0 else {
            return 0
        }

        let fromMine = fromAddress == ethereumKit.receiveAddress
        let sign: FloatingPointSign = fromMine ? .minus : .plus
        return Decimal(sign: sign, exponent: -decimal, significand: significand)
    }

    private func transactionRecord(fromTransaction transactionWithInternal: TransactionWithInternal) -> TransactionRecord {
        let transaction = transactionWithInternal.transaction

        var from = transaction.from
        var to = transaction.to

        var amount = convertAmount(amount: transaction.value, fromAddress: transaction.from)

        amount += transactionWithInternal.internalTransactions.reduce(0) { internalAmount, internalTransaction in
            from = internalTransaction.from
            to = internalTransaction.to
            return internalAmount + convertAmount(amount: internalTransaction.value, fromAddress: internalTransaction.from)
        }

        let type: TransactionType
        if transaction.from == transaction.to {
            type = .sentToSelf
        } else if amount < 0 {
            type = .outgoing
        } else {
            type = .incoming
        }

        let failed = (transaction.isError ?? 0) != 0
        let txHash = transaction.hash.toHexString()

        return TransactionRecord(
                uid: txHash,
                transactionHash: txHash,
                transactionIndex: transaction.transactionIndex ?? 0,
                interTransactionIndex: 0,
                type: type,
                blockHeight: transaction.blockNumber,
                confirmationsThreshold: EthereumBaseAdapter.confirmationsThreshold,
                amount: abs(amount),
                fee: transaction.gasUsed.map { Decimal(sign: .plus, exponent: -decimal, significand: Decimal($0 * transaction.gasPrice)) },
                date: Date(timeIntervalSince1970: transaction.timestamp),
                failed: failed,
                from: from.hex,
                to: to.hex,
                lockInfo: nil,
                conflictingHash: nil,
                showRawTransaction: false
        )
    }

    override func sendSingle(to address: String, value: Decimal, gasPrice: Int, gasLimit: Int, logger: Logger) -> Single<Void> {
        guard let amount = BigUInt(value.roundedString(decimal: decimal)) else {
            return Single.error(SendTransactionError.wrongAmount)
        }
        do {
            return try ethereumKit.sendSingle(address: Address(hex: address), value: amount, gasPrice: gasPrice, gasLimit: gasLimit)
                    .do(onSubscribe: { logger.debug("Sending to EthereumKit", save: true) })
                    .map { _ in ()}
                    .catchError { [weak self] error in
                        Single.error(self?.createSendError(from: error) ?? error)
                    }
        } catch {
            return Single.error(error)
        }

    }

}

extension EthereumAdapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try EthereumKit.Kit.clear(exceptFor: excludedWalletIds)
    }

}

// IAdapter
extension EthereumAdapter: IAdapter {

    func start() {
        // started via EthereumKitManager
    }

    func stop() {
        // stopped via EthereumKitManager
    }

    func refresh() {
        // refreshed via EthereumKitManager
    }

    var debugInfo: String {
        ethereumKit.debugInfo
    }

}

extension EthereumAdapter: IBalanceAdapter {

    var state: AdapterState {
        switch ethereumKit.syncState {
        case .synced: return .synced
        case .notSynced(let error): return .notSynced(error: error.convertedError)
        case .syncing: return .syncing(progress: 50, lastBlockDate: nil)
        }
    }

    var stateUpdatedObservable: Observable<Void> {
        ethereumKit.syncStateObservable.map { _ in () }
    }

    var balance: Decimal {
        balanceDecimal(kitBalance: ethereumKit.balance, decimal: EthereumAdapter.decimal)
    }

    var balanceUpdatedObservable: Observable<Void> {
        ethereumKit.balanceObservable.map { _ in () }
    }

}

extension EthereumAdapter: ISendEthereumAdapter {

    func availableBalance(gasPrice: Int, gasLimit: Int) -> Decimal {
        max(0, balance - fee(gasPrice: gasPrice, gasLimit: gasLimit))
    }

    var ethereumBalance: Decimal {
        balance
    }

    var minimumRequiredBalance: Decimal {
        0
    }

    var minimumSpendableAmount: Decimal? {
        nil
    }

    func fee(gasPrice: Int, gasLimit: Int) -> Decimal {
        let value = Decimal(gasPrice) * Decimal(gasLimit)
        return value / pow(10, EthereumAdapter.decimal)
    }

    func estimateGasLimit(to address: String?, value: Decimal, gasPrice: Int?) -> Single<Int> {
        guard let amount = BigUInt(value.roundedString(decimal: decimal)) else {
            return Single.error(SendTransactionError.wrongAmount)
        }

        var ethAddress: Address?
        if let address = address {
            ethAddress = try? Address(hex: address)
        }

        return ethereumKit.estimateGas(to: ethAddress, amount: amount, gasPrice: gasPrice)
    }

}

extension EthereumAdapter: ITransactionsAdapter {

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        ethereumKit.transactionsObservable.map { [weak self] in
            $0.compactMap { self?.transactionRecord(fromTransaction: $0) }
        }
    }

    func transactionsSingle(from: TransactionRecord?, limit: Int) -> Single<[TransactionRecord]> {
        ethereumKit.transactionsSingle(fromHash: from.flatMap { Data(hex: $0.transactionHash) }, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    transactions.compactMap { self?.transactionRecord(fromTransaction: $0) }
                }
    }

    func rawTransaction(hash: String) -> String? {
        nil
    }

}

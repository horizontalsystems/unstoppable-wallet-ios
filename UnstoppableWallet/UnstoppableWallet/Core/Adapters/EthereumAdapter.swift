import EthereumKit
import RxSwift
import BigInt
import HsToolKit

class EthereumAdapter: EthereumBaseAdapter {
    static let decimal = 18

    init(ethereumKit: EthereumKit.Kit) {
        super.init(ethereumKit: ethereumKit, decimal: EthereumAdapter.decimal)
    }

    private func convertAmount(amount: BigUInt, fromAddress: EthereumKit.Address) -> Decimal {
        guard let significand = Decimal(string: amount.description), significand != 0 else {
            return 0
        }

        let fromMine = fromAddress == ethereumKit.receiveAddress
        let sign: FloatingPointSign = fromMine ? .minus : .plus
        return Decimal(sign: sign, exponent: -decimal, significand: significand)
    }

    private func transactionRecord(fromTransaction fullTransaction: FullTransaction) -> TransactionRecord {
        let transaction = fullTransaction.transaction
        let receipt = fullTransaction.receiptWithLogs?.receipt

        var from = transaction.from
        var to = transaction.to

        var amount = convertAmount(amount: transaction.value, fromAddress: transaction.from)

        amount += fullTransaction.internalTransactions.reduce(0) { internalAmount, internalTransaction in
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

        let txHash = transaction.hash.toHexString()

        return TransactionRecord(
                uid: txHash,
                transactionHash: txHash,
                transactionIndex: receipt?.transactionIndex ?? 0,
                interTransactionIndex: 0,
                type: type,
                blockHeight: receipt?.blockNumber,
                confirmationsThreshold: EthereumBaseAdapter.confirmationsThreshold,
                amount: abs(amount),
                fee: receipt.map { Decimal(sign: .plus, exponent: -decimal, significand: Decimal($0.gasUsed * transaction.gasPrice)) },
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                failed: fullTransaction.failed,
                from: from.hex,
                to: to?.hex,
                lockInfo: nil,
                conflictingHash: nil,
                showRawTransaction: false,
                memo: nil
        )
    }

    override func sendSingle(to address: String, value: Decimal, gasPrice: Int, gasLimit: Int, logger: Logger) -> Single<Void> {
        guard let amount = BigUInt(value.roundedString(decimal: decimal)) else {
            return Single.error(SendTransactionError.wrongAmount)
        }
        do {
            return try ethereumKit.sendSingle(address: EthereumKit.Address(hex: address), value: amount, gasPrice: gasPrice, gasLimit: gasLimit)
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

    var balanceState: AdapterState {
        convertToAdapterState(ethereumSyncState: ethereumKit.syncState)
    }

    var balanceStateUpdatedObservable: Observable<Void> {
        ethereumKit.syncStateObservable.map { _ in () }
    }

    var balance: Decimal {
        balanceDecimal(kitBalance: ethereumKit.accountState?.balance, decimal: EthereumAdapter.decimal)
    }

    var balanceUpdatedObservable: Observable<Void> {
        ethereumKit.accountStateObservable.map { _ in () }
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

        var ethAddress: EthereumKit.Address?
        if let address = address {
            ethAddress = try? EthereumKit.Address(hex: address)
        }

        return ethereumKit.estimateGas(to: ethAddress, amount: amount, gasPrice: gasPrice)
    }

}

extension EthereumAdapter: ITransactionsAdapter {

    var transactionState: AdapterState {
        convertToAdapterState(ethereumSyncState: ethereumKit.transactionsSyncState)
    }

    var transactionStateUpdatedObservable: Observable<Void> {
        ethereumKit.transactionsSyncStateObservable.map { _ in () }
    }

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        ethereumKit.etherTransactionsObservable.map { [weak self] in
            $0.compactMap { self?.transactionRecord(fromTransaction: $0) }
        }
    }

    func transactionsSingle(from: TransactionRecord?, limit: Int) -> Single<[TransactionRecord]> {
        ethereumKit.etherTransactionsSingle(fromHash: from.flatMap { Data(hex: $0.transactionHash) }, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    transactions.compactMap { self?.transactionRecord(fromTransaction: $0) }
                }
    }

    func rawTransaction(hash: String) -> String? {
        nil
    }

}

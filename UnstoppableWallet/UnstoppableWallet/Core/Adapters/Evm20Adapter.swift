import EthereumKit
import Erc20Kit
import RxSwift
import BigInt
import HsToolKit

class Evm20Adapter: BaseEvmAdapter {
    private static let approveConfirmationsThreshold: Int? = nil
    let evm20Kit: Erc20Kit.Kit
    private let contractAddress: EthereumKit.Address

    init(evmKit: EthereumKit.Kit, contractAddress: String, decimal: Int) throws {
        let address = try EthereumKit.Address(hex: contractAddress)
        evm20Kit = try Erc20Kit.Kit.instance(ethereumKit: evmKit, contractAddress: address)
        self.contractAddress = address

        super.init(evmKit: evmKit, decimal: decimal)
    }

    private func convertAmount(amount: BigUInt, fromAddress: EthereumKit.Address) -> Decimal {
        guard let significand = Decimal(string: amount.description), significand != 0 else {
            return 0
        }

        let fromMine = fromAddress == evmKit.receiveAddress
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
            confirmationsThreshold: BaseEvmAdapter.confirmationsThreshold,
            amount: abs(amount),
            fee: receipt.map { Decimal(sign: .plus, exponent: -decimal, significand: Decimal($0.gasUsed * transaction.gasPrice)) },
            date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
            failed: fullTransaction.failed,
            from: from.eip55,
            to: to?.eip55,
            lockInfo: nil,
            conflictingHash: nil,
            showRawTransaction: false,
            memo: nil
        )
    }

//    private func transactionRecord(fromTransaction transaction: Transaction) -> TransactionRecord {
//        let mineAddress = evmKit.receiveAddress
//
//        var type: TransactionType = .sentToSelf
//        var amount: Decimal = 0
//        var confirmationsThreshold: Int? = BaseEvmAdapter.confirmationsThreshold
//
//        if let significand = Decimal(string: transaction.value.description) {
//            amount = Decimal(sign: .plus, exponent: -decimal, significand: significand)
//
//            let fromMine = transaction.from == mineAddress
//            let toMine = transaction.to == mineAddress
//
//            if transaction.type == .approve {
//                type = .approve
//                confirmationsThreshold = Self.approveConfirmationsThreshold
//            } else if fromMine && !toMine {
//                type = .outgoing
//            } else if !fromMine && toMine {
//                type = .incoming
//            }
//        }
//
//        let txHash = transaction.hash.toHexString()
//
//        return TransactionRecord(
//                uid: txHash + String(transaction.interTransactionIndex) + contractAddress.hex,
//                transactionHash: txHash,
//                transactionIndex: transaction.transactionIndex ?? 0,
//                interTransactionIndex: transaction.interTransactionIndex,
//                type: type,
//                blockHeight: transaction.fullTransaction.receiptWithLogs?.receipt.blockNumber,
//                confirmationsThreshold: confirmationsThreshold,
//                amount: abs(amount),
//                fee: nil,
//                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
//                failed: transaction.isError,
//                from: transaction.from.eip55,
//                to: transaction.to.eip55,
//                lockInfo: nil,
//                conflictingHash: nil,
//                showRawTransaction: false,
//                memo: nil
//        )
//    }

}

// IAdapter

extension Evm20Adapter: IAdapter {

    func start() {
        evm20Kit.start()
    }

    func stop() {
        evm20Kit.stop()
    }

    func refresh() {
        evmKit.refresh()
        evm20Kit.refresh()
    }

}

extension Evm20Adapter: IBalanceAdapter {

    var balanceState: AdapterState {
        convertToAdapterState(evmSyncState: evm20Kit.syncState)
    }

    var balanceStateUpdatedObservable: Observable<AdapterState> {
        evm20Kit.syncStateObservable.map { [unowned self] in self.convertToAdapterState(evmSyncState: $0) }
    }

    var balanceData: BalanceData {
        balanceData(balance: evm20Kit.balance)
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        evm20Kit.balanceObservable.map { [unowned self] in self.balanceData(balance: $0) }
    }

}

extension Evm20Adapter: ISendEthereumAdapter {

    func transactionData(amount: BigUInt, address: EthereumKit.Address) -> TransactionData {
        evm20Kit.transferTransactionData(to: address, value: amount)
    }

}

extension Evm20Adapter: IErc20Adapter {

    var pendingTransactions: [TransactionRecord] {
        evm20Kit.pendingTransactions().map { transactionRecord(fromTransaction: $0) }
    }

    func allowanceSingle(spenderAddress: EthereumKit.Address, defaultBlockParameter: DefaultBlockParameter = .latest) -> Single<Decimal> {
        evm20Kit.allowanceSingle(spenderAddress: spenderAddress, defaultBlockParameter: defaultBlockParameter)
                .map { [unowned self] allowanceString in
                    if let significand = Decimal(string: allowanceString) {
                        return Decimal(sign: .plus, exponent: -self.decimal, significand: significand)
                    }

                    return 0
                }
    }

}

extension Evm20Adapter: ITransactionsAdapter {

    var transactionState: AdapterState {
        convertToAdapterState(evmSyncState: evm20Kit.transactionsSyncState)
    }

    var transactionStateUpdatedObservable: Observable<Void> {
        evm20Kit.transactionsSyncStateObservable.map { _ in () }
    }

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        evm20Kit.transactionsObservable.map { [weak self] in
            $0.compactMap { self?.transactionRecord(fromTransaction: $0) }
        }
    }

    func transactionsSingle(from: TransactionRecord?, limit: Int) -> Single<[TransactionRecord]> {
        do {
            let fromHash = from.flatMap { Data(hex: $0.transactionHash) }
            return try evm20Kit.transactionsSingle(from: fromHash, limit: limit)
                    .map { [weak self] transactions -> [TransactionRecord] in
                        transactions.compactMap { self?.transactionRecord(fromTransaction: $0) }
                    }
        } catch {
            return Single.error(error)
        }
    }

    func rawTransaction(hash: String) -> String? {
        nil
    }

}

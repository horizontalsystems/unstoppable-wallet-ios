import EthereumKit
import Erc20Kit
import RxSwift
import BigInt
import HsToolKit
import class Erc20Kit.Transaction

class Evm20Adapter: BaseEvmAdapter {
    private static let approveConfirmationsThreshold: Int? = nil
    let evm20Kit: Erc20Kit.Kit
    private let contractAddress: EthereumKit.Address
    private let fee: Decimal
    private(set) var minimumRequiredBalance: Decimal
    private(set) var minimumSpendableAmount: Decimal?

    init(evmKit: EthereumKit.Kit, contractAddress: String, decimal: Int, fee: Decimal, minimumRequiredBalance: Decimal, minimumSpendableAmount: Decimal?) throws {
        let address = try EthereumKit.Address(hex: contractAddress)
        evm20Kit = try Erc20Kit.Kit.instance(ethereumKit: evmKit, contractAddress: address)
        self.contractAddress = address
        self.fee = fee
        self.minimumRequiredBalance = minimumRequiredBalance
        self.minimumSpendableAmount = minimumSpendableAmount

        super.init(evmKit: evmKit, decimal: decimal)
    }

    private func transactionRecord(fromTransaction transaction: Transaction) -> TransactionRecord {
        let mineAddress = evmKit.receiveAddress

        var type: TransactionType = .sentToSelf
        var amount: Decimal = 0
        var confirmationsThreshold: Int? = BaseEvmAdapter.confirmationsThreshold

        if let significand = Decimal(string: transaction.value.description) {
            amount = Decimal(sign: .plus, exponent: -decimal, significand: significand)

            let fromMine = transaction.from == mineAddress
            let toMine = transaction.to == mineAddress

            if transaction.type == .approve {
                type = .approve
                confirmationsThreshold = Self.approveConfirmationsThreshold
            } else if fromMine && !toMine {
                type = .outgoing
            } else if !fromMine && toMine {
                type = .incoming
            }
        }
        
        let txHash = transaction.hash.toHexString()

        return TransactionRecord(
            uid: txHash + String(transaction.interTransactionIndex) + contractAddress.hex,
                transactionHash: txHash,
                transactionIndex: transaction.transactionIndex ?? 0,
                interTransactionIndex: transaction.interTransactionIndex,
                type: type,
                blockHeight: transaction.fullTransaction.receiptWithLogs?.receipt.blockNumber,
                confirmationsThreshold: confirmationsThreshold,
                amount: abs(amount),
                fee: nil,
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                failed: transaction.isError,
                from: transaction.from.hex,
                to: transaction.to.hex,
                lockInfo: nil,
                conflictingHash: nil,
                showRawTransaction: false,
                memo: nil
        )
    }

    override func sendSingle(to address: String, value: Decimal, gasPrice: Int, gasLimit: Int, logger: Logger) -> Single<Void> {
        guard let amount = BigUInt(value.roundedString(decimal: decimal)),
              let toAddress = try? EthereumKit.Address(hex: address) else {
            return Single.error(SendTransactionError.wrongAmount)
        }

        let transactionInput = evm20Kit.transferTransactionData(to: toAddress, value: amount)

        return evmKit.sendSingle(address: transactionInput.to, value: transactionInput.value, transactionInput: transactionInput.input, gasPrice: gasPrice, gasLimit: gasLimit)
            .do(onSubscribe: { logger.debug("Sending to Erc20Kit", save: true) })
            .map { _ in ()}
            .catchError { [weak self] error in
                Single.error(self?.createSendError(from: error) ?? error)
            }
    }

}

extension Evm20Adapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try Erc20Kit.Kit.clear(exceptFor: excludedWalletIds)
    }

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
        evm20Kit.refresh()
    }

    var debugInfo: String {
        evmKit.debugInfo
    }

}

extension Evm20Adapter: IBalanceAdapter {

    var balanceState: AdapterState {
        convertToAdapterState(evmSyncState: evm20Kit.syncState)
    }

    var balanceStateUpdatedObservable: Observable<Void> {
        evm20Kit.syncStateObservable.map { _ in () }
    }

    var balance: Decimal {
        balanceDecimal(kitBalance: evm20Kit.balance, decimal: decimal)
    }

    var balanceUpdatedObservable: Observable<Void> {
        evm20Kit.balanceObservable.map { _ in () }
    }

}

extension Evm20Adapter: ISendEthereumAdapter {

    func availableBalance(gasPrice: Int, gasLimit: Int) -> Decimal {
        max(0, balance - fee)
    }

    var ethereumBalance: Decimal {
        balanceDecimal(kitBalance: evmKit.accountState?.balance, decimal: EvmAdapter.decimal)
    }

    func fee(gasPrice: Int, gasLimit: Int) -> Decimal {
        let value = Decimal(gasPrice) * Decimal(gasLimit)
        return value / pow(10, EvmAdapter.decimal)
    }

    func estimateGasLimit(to address: String?, value: Decimal, gasPrice: Int?) -> Single<Int> {
        guard let amount = BigUInt(value.roundedString(decimal: decimal)) else {
            return Single.error(SendTransactionError.wrongAmount)
        }

        guard let address = address, let toAddress = try? EthereumKit.Address(hex: address) else {
            return Single.just(EthereumKit.Kit.defaultGasLimit)
        }

        let data = evm20Kit.transferTransactionData(to: toAddress, value: amount)
        return evmKit.estimateGas(transactionData: data, gasPrice: gasPrice)
    }

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
            let fromData = from.flatMap { record in
                Data(hex: record.transactionHash).map {
                    (hash: $0, interTransactionIndex: record.interTransactionIndex)
                }
            }
            return try evm20Kit.transactionsSingle(from: fromData, limit: limit)
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

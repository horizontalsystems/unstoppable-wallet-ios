import EthereumKit
import Erc20Kit
import RxSwift
import BigInt
import HsToolKit
import class Erc20Kit.Transaction

class Erc20Adapter: EthereumBaseAdapter {
    private static let approveConfirmationsThreshold: Int? = nil
    let erc20Kit: Erc20Kit.Kit
    private let contractAddress: EthereumKit.Address
    private let fee: Decimal
    private(set) var minimumRequiredBalance: Decimal
    private(set) var minimumSpendableAmount: Decimal?

    init(ethereumKit: EthereumKit.Kit, contractAddress: String, decimal: Int, fee: Decimal, minimumRequiredBalance: Decimal, minimumSpendableAmount: Decimal?) throws {
        let address = try EthereumKit.Address(hex: contractAddress)
        erc20Kit = try Erc20Kit.Kit.instance(ethereumKit: ethereumKit, contractAddress: address)
        self.contractAddress = address
        self.fee = fee
        self.minimumRequiredBalance = minimumRequiredBalance
        self.minimumSpendableAmount = minimumSpendableAmount

        super.init(ethereumKit: ethereumKit, decimal: decimal)
    }

    private func transactionRecord(fromTransaction transaction: Transaction) -> TransactionRecord {
        let mineAddress = ethereumKit.receiveAddress

        var type: TransactionType = .sentToSelf
        var amount: Decimal = 0
        var confirmationsThreshold: Int? = EthereumBaseAdapter.confirmationsThreshold

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

        let transactionInput = erc20Kit.transferTransactionData(to: toAddress, value: amount)

        return ethereumKit.sendSingle(address: transactionInput.to, value: transactionInput.value, transactionInput: transactionInput.input, gasPrice: gasPrice, gasLimit: gasLimit)
            .do(onSubscribe: { logger.debug("Sending to Erc20Kit", save: true) })
            .map { _ in ()}
            .catchError { [weak self] error in
                Single.error(self?.createSendError(from: error) ?? error)
            }
    }

}

extension Erc20Adapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try Erc20Kit.Kit.clear(exceptFor: excludedWalletIds)
    }

}

// IAdapter
extension Erc20Adapter: IAdapter {

    func start() {
        erc20Kit.start()
    }

    func stop() {
        erc20Kit.stop()
    }

    func refresh() {
        erc20Kit.refresh()
    }

    var debugInfo: String {
        ethereumKit.debugInfo
    }

}

extension Erc20Adapter: IBalanceAdapter {

    var balanceState: AdapterState {
        convertToAdapterState(ethereumSyncState: erc20Kit.syncState)
    }

    var balanceStateUpdatedObservable: Observable<Void> {
        erc20Kit.syncStateObservable.map { _ in () }
    }

    var balance: Decimal {
        balanceDecimal(kitBalance: erc20Kit.balance, decimal: decimal)
    }

    var balanceUpdatedObservable: Observable<Void> {
        erc20Kit.balanceObservable.map { _ in () }
    }

}

extension Erc20Adapter: ISendEthereumAdapter {

    func availableBalance(gasPrice: Int, gasLimit: Int) -> Decimal {
        max(0, balance - fee)
    }

    var ethereumBalance: Decimal {
        balanceDecimal(kitBalance: ethereumKit.accountState?.balance, decimal: EthereumAdapter.decimal)
    }

    func fee(gasPrice: Int, gasLimit: Int) -> Decimal {
        let value = Decimal(gasPrice) * Decimal(gasLimit)
        return value / pow(10, EthereumAdapter.decimal)
    }

    func estimateGasLimit(to address: String?, value: Decimal, gasPrice: Int?) -> Single<Int> {
        guard let amount = BigUInt(value.roundedString(decimal: decimal)) else {
            return Single.error(SendTransactionError.wrongAmount)
        }

        guard let address = address, let toAddress = try? EthereumKit.Address(hex: address) else {
            return Single.just(EthereumKit.Kit.defaultGasLimit)
        }

        let data = erc20Kit.transferTransactionData(to: toAddress, value: amount)
        return ethereumKit.estimateGas(transactionData: data, gasPrice: gasPrice)
    }

}

extension Erc20Adapter: IErc20Adapter {

    var pendingTransactions: [TransactionRecord] {
        erc20Kit.pendingTransactions().map { transactionRecord(fromTransaction: $0) }
    }

    func allowanceSingle(spenderAddress: EthereumKit.Address, defaultBlockParameter: DefaultBlockParameter = .latest) -> Single<Decimal> {
        erc20Kit.allowanceSingle(spenderAddress: spenderAddress, defaultBlockParameter: defaultBlockParameter)
                .map { [unowned self] allowanceString in
                    if let significand = Decimal(string: allowanceString) {
                        return Decimal(sign: .plus, exponent: -self.decimal, significand: significand)
                    }

                    return 0
                }
    }

}

extension Erc20Adapter: ITransactionsAdapter {

    var transactionState: AdapterState {
        convertToAdapterState(ethereumSyncState: erc20Kit.transactionsSyncState)
    }

    var transactionStateUpdatedObservable: Observable<Void> {
        erc20Kit.transactionsSyncStateObservable.map { _ in () }
    }

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        erc20Kit.transactionsObservable.map { [weak self] in
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
            return try erc20Kit.transactionsSingle(from: fromData, limit: limit)
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

import EthereumKit
import Erc20Kit
import RxSwift
import class Erc20Kit.TransactionInfo

class Erc20Adapter: EthereumBaseAdapter {
    private let erc20Kit: Erc20Kit.Kit
    private let contractAddress: String
    private let fee: Decimal
    private let gasLimit: Int?
    private(set) var minimumRequiredBalance: Decimal
    private(set) var minimumSpendableAmount: Decimal?

    init(ethereumKit: EthereumKit.Kit, contractAddress: String, decimal: Int, fee: Decimal, gasLimit: Int? = nil, minimumRequiredBalance: Decimal, minimumSpendableAmount: Decimal?) throws {
        self.erc20Kit = try Erc20Kit.Kit.instance(ethereumKit: ethereumKit, contractAddress: contractAddress)
        self.contractAddress = contractAddress
        self.fee = fee
        self.gasLimit = gasLimit
        self.minimumRequiredBalance = minimumRequiredBalance
        self.minimumSpendableAmount = minimumSpendableAmount

        super.init(ethereumKit: ethereumKit, decimal: decimal)
    }

    private func transactionRecord(fromTransaction transaction: TransactionInfo) -> TransactionRecord {
        var type: TransactionType = .sentToSelf
        var amount: Decimal = 0

        if let significand = Decimal(string: transaction.value) {
            amount = Decimal(sign: .plus, exponent: -decimal, significand: significand)

            let mineAddress = ethereumKit.receiveAddress.lowercased()
            let fromMine = transaction.from.lowercased() == mineAddress
            let toMine = transaction.to.lowercased() == mineAddress

            if fromMine && !toMine {
                type = .outgoing
            } else if !fromMine && toMine {
                type = .incoming
            }
        }

        return TransactionRecord(
                uid: transaction.transactionHash + String(transaction.interTransactionIndex),
                transactionHash: transaction.transactionHash,
                transactionIndex: transaction.transactionIndex ?? 0,
                interTransactionIndex: transaction.interTransactionIndex,
                type: type,
                blockHeight: transaction.blockNumber,
                amount: abs(amount),
                fee: nil,
                date: Date(timeIntervalSince1970: transaction.timestamp),
                failed: transaction.isError,
                from: transaction.from,
                to: transaction.to,
                lockInfo: nil
        )
    }

    override func sendSingle(to address: String, value: String, gasPrice: Int, gasLimit: Int) -> Single<Void> {
        do {
            return try erc20Kit.sendSingle(to: address, value: value, gasPrice: gasPrice, gasLimit: gasLimit)
                    .map { _ in ()}
                    .catchError { [weak self] error in
                        Single.error(self?.createSendError(from: error) ?? error)
                    }
        } catch {
            return Single.error(error)
        }
    }

    override func estimateGasLimit(to address: String, value: Decimal, gasPrice: Int?) -> Single<Int> {
        if let gasLimit = gasLimit {
            return Single.just(gasLimit)
        }
        return erc20Kit.estimateGas(to: address, contractAddress: contractAddress, value: value.roundedString(decimal: decimal), gasPrice: gasPrice)
    }

}

extension Erc20Adapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try Erc20Kit.Kit.clear(exceptFor: excludedWalletIds)
    }

}

extension Erc20Adapter: IBalanceAdapter {

    var state: AdapterState {
        switch erc20Kit.syncState {
        case .synced: return .synced
        case .notSynced: return .notSynced
        case .syncing: return .syncing(progress: 50, lastBlockDate: nil)
        }
    }

    var stateUpdatedObservable: Observable<Void> {
        erc20Kit.syncStateObservable.map { _ in () }
    }

    var balance: Decimal {
        guard let balanceString = erc20Kit.balance else {
            return 0
        }

        return balanceDecimal(balanceString: balanceString, decimal: decimal)
    }

    var balanceUpdatedObservable: Observable<Void> {
        erc20Kit.balanceObservable.map { _ in () }
    }

}

extension Erc20Adapter: ISendEthereumAdapter {

    func availableBalance(gasPrice: Int, gasLimit: Int?) -> Decimal {
        max(0, balance - fee)
    }

    var ethereumBalance: Decimal {
        balanceDecimal(balanceString: ethereumKit.balance, decimal: EthereumAdapter.decimal)
    }

    func fee(gasPrice: Int, gasLimit: Int) -> Decimal {
        let value = Decimal(gasPrice) * Decimal(gasLimit)
        return value / pow(10, EthereumAdapter.decimal)
    }

}

extension Erc20Adapter: ITransactionsAdapter {

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        erc20Kit.transactionsObservable.map { [weak self] in
            $0.compactMap { self?.transactionRecord(fromTransaction: $0) }
        }
    }

    func transactionsSingle(from: TransactionRecord?, limit: Int) -> Single<[TransactionRecord]> {
        do {
            return try erc20Kit.transactionsSingle(from: from.flatMap { (hash: $0.transactionHash, interTransactionIndex: $0.interTransactionIndex) }, limit: limit)
                    .map { [weak self] transactions -> [TransactionRecord] in
                        transactions.compactMap { self?.transactionRecord(fromTransaction: $0) }
                    }
        } catch {
            return Single.error(error)
        }
    }

}

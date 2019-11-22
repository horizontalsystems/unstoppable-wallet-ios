import EthereumKit
import Erc20Kit
import RxSwift
import class Erc20Kit.TransactionInfo

class Erc20Adapter: EthereumBaseAdapter {
    private let erc20Kit: Erc20Kit
    private let contractAddress: String
    private let fee: Decimal
    private(set) var minimumRequiredBalance: Decimal

    init(ethereumKit: EthereumKit, contractAddress: String, decimal: Int, fee: Decimal, minimumRequiredBalance: Decimal) throws {
        self.erc20Kit = try Erc20Kit.instance(ethereumKit: ethereumKit, contractAddress: contractAddress)
        self.contractAddress = contractAddress
        self.fee = fee
        self.minimumRequiredBalance = minimumRequiredBalance

        super.init(ethereumKit: ethereumKit, decimal: decimal)
    }

    private func transactionRecord(fromTransaction transaction: TransactionInfo) -> TransactionRecord {
        let mineAddress = ethereumKit.receiveAddress

        let from = TransactionAddress(
                address: transaction.from,
                mine: transaction.from == mineAddress
        )

        let to = TransactionAddress(
                address: transaction.to,
                mine: transaction.to == mineAddress
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
                transactionHash: transaction.transactionHash,
                transactionIndex: transaction.transactionIndex ?? 0,
                interTransactionIndex: transaction.interTransactionIndex,
                blockHeight: transaction.blockNumber,
                amount: amount,
                fee: nil,
                date: Date(timeIntervalSince1970: transaction.timestamp),
                from: [from],
                to: [to]
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
        erc20Kit.estimateGas(to: address, contractAddress: contractAddress, value: value.roundedString(decimal: decimal), gasPrice: gasPrice)
    }

}

extension Erc20Adapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try Erc20Kit.clear(exceptFor: excludedWalletIds)
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

    func transactionsSingle(from: (hash: String, interTransactionIndex: Int)?, limit: Int) -> Single<[TransactionRecord]> {
        do {
            return try erc20Kit.transactionsSingle(from: from, limit: limit)
                    .map { [weak self] transactions -> [TransactionRecord] in
                        transactions.compactMap { self?.transactionRecord(fromTransaction: $0) }
                    }
        } catch {
            return Single.error(error)
        }
    }

}

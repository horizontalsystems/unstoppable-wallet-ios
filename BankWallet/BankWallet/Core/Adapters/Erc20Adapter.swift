import EthereumKit
import Erc20Kit
import RxSwift
import class Erc20Kit.TransactionInfo

class Erc20Adapter: EthereumBaseAdapter {
    let feeCoinCode: CoinCode? = "ETH"

    private let erc20Kit: Erc20Kit
    private let fee: Decimal

    init(coin: Coin, ethereumKit: EthereumKit, contractAddress: String, decimal: Int, fee: Decimal, addressParser: IAddressParser, feeRateProvider: IFeeRateProvider) throws {
        self.erc20Kit = try Erc20Kit.instance(ethereumKit: ethereumKit, contractAddress: contractAddress)
        self.fee = fee

        super.init(coin: coin, ethereumKit: ethereumKit, decimal: decimal, addressParser: addressParser, feeRateProvider: feeRateProvider)
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
            let sign: FloatingPointSign = from.mine ? .minus : .plus
            amount = Decimal(sign: sign, exponent: -decimal, significand: significand)
        }

        return TransactionRecord(
                transactionHash: transaction.transactionHash,
                transactionIndex: transaction.transactionIndex ?? 0,
                interTransactionIndex: transaction.interTransactionIndex,
                blockHeight: transaction.blockNumber,
                amount: amount,
                date: Date(timeIntervalSince1970: transaction.timestamp),
                from: [from],
                to: [to]
        )
    }

    override func sendSingle(to address: String, value: String, gasPrice: Int) -> Single<Void> {
        do {
            return try erc20Kit.sendSingle(to: address, value: value, gasPrice: gasPrice)
                    .map { _ in ()}
                    .catchError { [weak self] error in
                        return Single.error(self?.createSendError(from: error) ?? error)
                    }
        } catch {
            return Single.error(error)
        }
    }

}

extension Erc20Adapter: IAdapter {

    var state: AdapterState {
        switch erc20Kit.syncState {
        case .synced: return .synced
        case .notSynced: return .notSynced
        case .syncing: return .syncing(progress: 50, lastBlockDate: nil)
        }
    }

    var stateUpdatedObservable: Observable<Void> {
        return erc20Kit.syncStateObservable.map { _ in () }
    }

    var balance: Decimal {
        guard let balanceString = erc20Kit.balance else {
            return 0
        }

        return balanceDecimal(balanceString: balanceString, decimal: decimal)
    }

    var balanceUpdatedObservable: Observable<Void> {
        return erc20Kit.balanceObservable.map { _ in () }
    }

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        return erc20Kit.transactionsObservable.map { [weak self] in
            $0.compactMap { self?.transactionRecord(fromTransaction: $0) }
        }
    }

    func transactionsSingle(from: (hash: String, interTransactionIndex: Int)?, limit: Int) -> Single<[TransactionRecord]> {
        do {
            return try erc20Kit.transactionsSingle(from: from, limit: limit)
                    .map { [weak self] transactions -> [TransactionRecord] in
                        return transactions.compactMap { self?.transactionRecord(fromTransaction: $0) }
                    }
        } catch {
            return Single.error(error)
        }
    }

    func availableBalance(for address: String?, feeRatePriority: FeeRatePriority) -> Decimal {
        return max(0, balance - fee)
    }

    func fee(for value: Decimal, address: String?, feeRatePriority: FeeRatePriority) -> Decimal {
        return erc20Kit.fee(gasPrice: feeRateProvider.ethereumGasPrice(for: feeRatePriority)) / pow(10, EthereumAdapter.decimal)
    }

    func validate(amount: Decimal, address: String?, feeRatePriority: FeeRatePriority) -> [SendStateError] {
        var errors = [SendStateError]()
        if amount > availableBalance(for: address, feeRatePriority: feeRatePriority) {
            errors.append(.insufficientAmount)
        }

        let ethereumBalance = balanceDecimal(balanceString: ethereumKit.balance, decimal: EthereumAdapter.decimal)

        if ethereumBalance < fee(for: amount, address: address, feeRatePriority: feeRatePriority) {
            errors.append(.insufficientFeeBalance)
        }
        return errors
    }

}

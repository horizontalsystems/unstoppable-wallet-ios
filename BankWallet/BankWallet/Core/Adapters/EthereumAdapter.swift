import EthereumKit
import RxSwift

class EthereumAdapter: EthereumBaseAdapter {
    static let decimal = 18

    init(wallet: Wallet, ethereumKit: EthereumKit, addressParser: IAddressParser, feeRateProvider: IFeeRateProvider) {
        super.init(wallet: wallet, ethereumKit: ethereumKit, decimal: EthereumAdapter.decimal, addressParser: addressParser, feeRateProvider: feeRateProvider)
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

extension EthereumAdapter: IAdapter {

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

    func availableBalance(params: [String : Any]) throws -> Decimal {

        return try max(0, balance - fee(params: params))
    }

    func fee(params: [String : Any]) throws -> Decimal {
        guard let feeRatePriority: FeeRatePriority = params[AdapterField.feeRateRriority.rawValue] as? FeeRatePriority else {
            throw AdapterError.wrongParameters
        }

        return ethereumKit.fee(gasPrice: feeRateProvider.ethereumGasPrice(for: feeRatePriority)) / pow(10, EthereumAdapter.decimal)
    }

    func validate(params: [String : Any])throws -> [SendStateError] {
        guard let amount: Decimal = params[AdapterField.amount.rawValue] as? Decimal else {
            throw AdapterError.wrongParameters
        }

        var errors = [SendStateError]()
        let balance = try availableBalance(params: params)
        if amount > balance {
            errors.append(.insufficientAmount(availableBalance: balance))
        }
        return errors
    }

}

extension EthereumAdapter {

    static func clear() throws {
        try EthereumKit.clear()
    }

}

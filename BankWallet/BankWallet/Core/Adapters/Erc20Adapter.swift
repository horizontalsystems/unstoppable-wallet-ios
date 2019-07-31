import EthereumKit
import Erc20Kit
import RxSwift
import class Erc20Kit.TransactionInfo

class Erc20Adapter: EthereumBaseAdapter {
    let feeCoinCode: CoinCode? = "ETH"

    private let erc20Kit: Erc20Kit
    private let fee: Decimal

    init(wallet: Wallet, ethereumKit: EthereumKit, contractAddress: String, decimal: Int, fee: Decimal, addressParser: IAddressParser, feeRateProvider: IFeeRateProvider) throws {
        self.erc20Kit = try Erc20Kit.instance(ethereumKit: ethereumKit, contractAddress: contractAddress)
        self.fee = fee

        super.init(wallet: wallet, ethereumKit: ethereumKit, decimal: decimal, addressParser: addressParser, feeRateProvider: feeRateProvider)
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

    func availableBalance(params: [String : Any]) -> Decimal {
        return max(0, balance - fee)
    }

    func fee(params: [String : Any]) -> Decimal {
        let feeRatePriority: FeeRatePriority = (params[AdapterFields.feeRateRriority.rawValue] as? FeeRatePriority) ?? .medium

        return erc20Kit.fee(gasPrice: feeRateProvider.ethereumGasPrice(for: feeRatePriority)) / pow(10, EthereumAdapter.decimal)
    }

    func validate(params: [String : Any]) throws -> [SendStateError] {
        var errors = [SendStateError]()

        if let amount: Decimal = params[AdapterFields.amount.rawValue] as? Decimal {
            let balance = availableBalance(params: params)
            if amount > balance {
                errors.append(.insufficientAmount(availableBalance: balance))
            }
        }

        let ethereumBalance = balanceDecimal(balanceString: ethereumKit.balance, decimal: EthereumAdapter.decimal)

        let expectedFee = fee(params: params)
        if ethereumBalance < expectedFee {
            errors.append(.insufficientFeeBalance(fee: expectedFee))
        }
        return errors
    }

}

extension Erc20Adapter {

    static func clear() throws {
        try Erc20Kit.clear()
    }

}

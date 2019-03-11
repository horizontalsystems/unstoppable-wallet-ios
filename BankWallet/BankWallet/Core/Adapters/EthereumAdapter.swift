import HSEthereumKit
import RxSwift

class EthereumAdapter: EthereumBaseAdapter {
    static let decimal = 18

    init(coin: Coin, ethereumKit: EthereumKit) {
        super.init(coin: coin, ethereumKit: ethereumKit, decimal: EthereumAdapter.decimal)

        ethereumKit.delegate = self
    }

    override func transactionsObservable(hashFrom: String?, limit: Int) -> Single<[EthereumTransaction]> {
        return ethereumKit.transactionsSingle(fromHash: hashFrom, limit: limit)
    }

    override func sendSingle(to address: String, amount: String, feeRate: Int) -> Single<Void> {
        return ethereumKit.sendSingle(to: address, amount: amount)
                .map { _ in ()}
                .catchError { [weak self] error in
                    return Single.error(self?.createSendError(from: error) ?? error)
                }
    }

}

extension EthereumAdapter: IAdapter {

    func stop() {
    }

    var balance: Decimal {
        return balanceDecimal(balanceString: ethereumKit.balance, decimal: EthereumAdapter.decimal)
    }

    var feeRates: FeeRates {
        return FeeRates(value: (8, 40, 80))
    }

    func refresh() {
        ethereumKit.start()
    }

    func availableBalance(for address: String?, feeRate: Int) -> Decimal {
        return max(0, balance - fee(for: balance, address: address, feeRate: feeRate))
    }

    func fee(for value: Decimal, address: String?, feeRate: Int) -> Decimal {
        return ethereumKit.fee() / pow(10, EthereumAdapter.decimal)
    }

    func validate(amount: Decimal, address: String?, feeRate: Int) -> [SendStateError] {
        var errors = [SendStateError]()
        if amount > availableBalance(for: address, feeRate: feeRate) {
            errors.append(.insufficientAmount)
        }
        return errors
    }

}

extension EthereumAdapter: IEthereumKitDelegate {

}

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

    override func sendSingle(to address: String, amount: String) -> Single<Void> {
        return ethereumKit.sendSingle(to: address, amount: amount)
                .map { _ in ()}
                .catchError({ [weak self] error in
                    return Single.error(self?.createSendError(from: error) ?? error)
                })
    }

}

extension EthereumAdapter: IAdapter {

    func stop() {
    }

    var balance: Decimal {
        return balanceDecimal(balanceString: ethereumKit.balance, decimal: EthereumAdapter.decimal)
    }

    func refresh() {
        ethereumKit.start()
    }

    func availableBalance(for address: String?) -> Decimal {
        return max(0, balance - fee(for: balance, address: address))
    }

    func fee(for value: Decimal, address: String?) -> Decimal {
        return ethereumKit.fee() / pow(10, EthereumAdapter.decimal)
    }

    func validate(amount: Decimal, address: String?) -> [SendStateError] {
        var errors = [SendStateError]()
        if amount > availableBalance(for: address) {
            errors.append(.insufficientAmount)
        }
        return errors
    }

}

extension EthereumAdapter: IEthereumKitDelegate {

}

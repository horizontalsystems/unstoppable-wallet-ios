import HSEthereumKit
import RxSwift

class EthereumAdapter: EthereumBaseAdapter {

    init(coin: Coin, ethereumKit: EthereumKit) {
        super.init(coin: coin, ethereumKit: ethereumKit, decimal: 18)

        ethereumKit.delegate = self
    }

    override func transactionsObservable(hashFrom: String?, limit: Int) -> Single<[EthereumTransaction]> {
        return ethereumKit.transactions(fromHash: hashFrom, limit: limit)
    }

}

extension EthereumAdapter: IAdapter {

    func stop() {
    }

    var balance: Decimal {
        return ethereumKit.balance
    }

    func refresh() {
        ethereumKit.refresh()
    }

    func send(to address: String, value: Decimal, completion: ((Error?) -> ())?) {
        ethereumKit.send(to: address, value: value, gasPrice: nil, completion: completion)
    }

    func availableBalance(for address: String?) -> Decimal {
        return max(0, balance - fee(for: balance, address: address))
    }

    func fee(for value: Decimal, address: String?) -> Decimal {
        return ethereumKit.fee
    }

    func validate(amount: Decimal, address: String?) -> [SendStateError] {
        var errors = [SendStateError]()
        if amount > availableBalance(for: address) {
            errors.append(.insufficientAmount)
        }
        return errors
    }

}

extension EthereumAdapter: EthereumKitDelegate {

}
